"""CutForge AI MVP: local-first, nondestructive video editing API."""
from __future__ import annotations

import json
import math
import os
import re
import shutil
import subprocess
import threading
import uuid
from pathlib import Path

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field

ROOT = Path(__file__).resolve().parents[1]
DATA = Path(os.environ.get("CUTFORGE_DATA", str(ROOT / "data"))).resolve()
PROJECTS = DATA / "projects"
EFFECTS = DATA / "effects"
EXTENSIONS = {".mp4", ".mov", ".mkv", ".webm", ".m4v"}
AUDIO_EXTENSIONS = {".wav", ".mp3", ".ogg", ".m4a", ".aac"}
STYLE_FILTERS = {
    "none": "null",
    "vivid": "eq=contrast=1.08:saturation=1.25",
    "warm": "eq=contrast=1.035:saturation=1.12:gamma_r=1.06:gamma_b=0.94",
    "mono": "hue=s=0",
    "cinematic": "eq=contrast=1.15:saturation=0.83",
}
for folder in (PROJECTS, EFFECTS):
    folder.mkdir(parents=True, exist_ok=True)

app = FastAPI(title="CutForge AI", version="0.1.0")
JOBS: dict[str, dict] = {}
JOB_LOCK = threading.Lock()


def tool(name: str) -> str:
    executable = shutil.which(name)
    if not executable:
        raise HTTPException(503, f"{name} not installed. Install FFmpeg and add it to PATH.")
    return executable


def project_dir(pid: str) -> Path:
    if not re.fullmatch(r"[a-f0-9]{32}", pid):
        raise HTTPException(404, "Project not found")
    folder = PROJECTS / pid
    if not (folder / "project.json").exists():
        raise HTTPException(404, "Project not found")
    return folder


def load_project(pid: str) -> dict:
    return json.loads((project_dir(pid) / "project.json").read_text(encoding="utf8"))


def save_project(project: dict) -> None:
    path = project_dir(project["id"]) / "project.json"
    temp = path.with_suffix(".tmp")
    temp.write_text(json.dumps(project, ensure_ascii=False, indent=2), encoding="utf8")
    temp.replace(path)


def probe(path: Path) -> tuple[float, bool]:
    proc = subprocess.run(
        [tool("ffprobe"), "-v", "error", "-show_entries", "format=duration:stream=codec_type", "-of", "json", str(path)],
        text=True, capture_output=True, timeout=45,
    )
    if proc.returncode:
        raise HTTPException(422, "The file is not a readable video/audio file")
    try:
        info = json.loads(proc.stdout)
        duration = float(info["format"]["duration"])
        streams = info.get("streams", [])
        if not math.isfinite(duration) or duration <= 0:
            raise ValueError
        if not any(s.get("codec_type") == "video" for s in streams):
            raise ValueError
        return duration, any(s.get("codec_type") == "audio" for s in streams)
    except (ValueError, KeyError, TypeError) as exc:
        raise HTTPException(422, "File contains no valid video stream") from exc


def asset_path(project: dict) -> Path:
    return project_dir(project["id"]) / project["source"]


class Segment(BaseModel):
    start: float = Field(ge=0)
    end: float = Field(gt=0)


class EffectUse(BaseModel):
    id: str
    at: float = Field(ge=0)
    volume: float = Field(default=0.7, ge=0, le=2)


class Edits(BaseModel):
    segments: list[Segment] = Field(min_length=1, max_length=120)
    style: str = "none"
    effects: list[EffectUse] = Field(default_factory=list, max_length=40)


def validate_edits(edits: Edits, duration: float) -> float:
    if edits.style not in STYLE_FILTERS:
        raise HTTPException(422, "Unknown color preset")
    previous_end = 0.0
    total = 0.0
    for segment in edits.segments:
        if segment.end <= segment.start + 0.045 or segment.end > duration + 0.055:
            raise HTTPException(422, "Invalid segment boundaries")
        if segment.start + 0.002 < previous_end:
            raise HTTPException(422, "Segments must be ordered and not overlap")
        previous_end = segment.end
        total += segment.end - segment.start
    for effect in edits.effects:
        if not re.fullmatch(r"[a-f0-9]{32}", effect.id) or not any((EFFECTS / (effect.id + ext)).exists() for ext in AUDIO_EXTENSIONS):
            raise HTTPException(422, "Unknown sound effect")
        if effect.at > total:
            raise HTTPException(422, "Effect timestamp exceeds edited duration")
    return total


@app.get("/api/health")
def health():
    return {"ok": True, "ffmpeg": bool(shutil.which("ffmpeg")), "ffprobe": bool(shutil.which("ffprobe"))}


@app.get("/api/projects")
def list_projects():
    result = []
    for path in PROJECTS.glob("*/project.json"):
        try:
            p = json.loads(path.read_text(encoding="utf8"))
            result.append({"id": p["id"], "name": p["name"], "duration": p["duration"]})
        except (ValueError, KeyError):
            continue
    return sorted(result, key=lambda p: p["name"].lower())


@app.post("/api/projects")
async def upload_video(file: UploadFile = File(...)):
    filename = Path(file.filename or "video.mp4").name
    suffix = Path(filename).suffix.lower()
    if suffix not in EXTENSIONS:
        raise HTTPException(415, "Supported video formats: MP4, MOV, MKV, WebM, M4V")
    pid = uuid.uuid4().hex
    folder = PROJECTS / pid
    folder.mkdir(parents=True)
    output = folder / ("source" + suffix)
    copied = 0
    try:
        with output.open("wb") as dest:
            while chunk := await file.read(4 * 1024 * 1024):
                copied += len(chunk)
                if copied > 25 * 1024**3:
                    raise HTTPException(413, "Video exceeds 25 GiB limit")
                dest.write(chunk)
        duration, has_audio = probe(output)
        project = {"id": pid, "name": filename, "source": output.name, "duration": duration,
                   "has_audio": has_audio, "segments": [{"start": 0, "end": duration}],
                   "style": "none", "effects": [], "suggestions": []}
        (folder / "project.json").write_text(json.dumps(project, ensure_ascii=False, indent=2), encoding="utf8")
        return project
    except Exception:
        shutil.rmtree(folder, ignore_errors=True)
        raise
    finally:
        await file.close()


@app.get("/api/projects/{pid}")
def get_project(pid: str):
    return load_project(pid)


@app.get("/api/projects/{pid}/media")
def media(pid: str):
    p = load_project(pid)
    return FileResponse(asset_path(p), media_type="video/mp4")


@app.post("/api/projects/{pid}/analyze")
def analyze(pid: str, threshold: float = -36, min_pause: float = 0.6):
    project = load_project(pid)
    if not -65 <= threshold <= -15 or not 0.2 <= min_pause <= 10:
        raise HTTPException(422, "Invalid detection settings")
    if not project["has_audio"]:
        return {"suggestions": [], "note": "Video has no audio track"}
    process = subprocess.run(
        [tool("ffmpeg"), "-hide_banner", "-nostdin", "-i", str(asset_path(project)),
         "-vn", "-af", f"silencedetect=noise={threshold}dB:d={min_pause}", "-f", "null", "-"],
        capture_output=True, text=True,
    )
    if process.returncode:
        raise HTTPException(500, "FFmpeg failed during silence detection")
    starts = re.findall(r"silence_start:\s*([\d.]+)", process.stderr)
    ends = re.findall(r"silence_end:\s*([\d.]+)", process.stderr)
    # Parse each line in order so we also handle a silence that runs to EOF.
    silences = []
    start = None
    for line in process.stderr.splitlines():
        a = re.search(r"silence_start:\s*([\d.]+)", line)
        b = re.search(r"silence_end:\s*([\d.]+)", line)
        if a:
            start = float(a.group(1))
        if b and start is not None:
            end = float(b.group(1))
            if end - start >= min_pause:
                silences.append({"start": round(start, 3), "end": round(min(end, project["duration"]), 3)})
            start = None
    if start is not None and project["duration"] - start >= min_pause:
        silences.append({"start": round(start, 3), "end": project["duration"]})
    project["suggestions"] = silences
    save_project(project)
    return {"suggestions": silences, "note": f"Found {len(silences)} silence regions"}


@app.put("/api/projects/{pid}/edit")
def update_edit(pid: str, edits: Edits):
    project = load_project(pid)
    validate_edits(edits, project["duration"])
    project.update(edits.model_dump())
    save_project(project)
    return project


def stored_effect(effect_id: str) -> Path:
    for ext in AUDIO_EXTENSIONS:
        path = EFFECTS / (effect_id + ext)
        if path.exists():
            return path
    raise ValueError("Effect missing")


@app.get("/api/effects")
def list_effects():
    assets = []
    for path in EFFECTS.iterdir():
        if path.suffix in AUDIO_EXTENSIONS:
            label_file = EFFECTS / (path.stem + ".json")
            label = json.loads(label_file.read_text(encoding="utf8"))["name"] if label_file.exists() else path.name
            assets.append({"id": path.stem, "name": label})
    return sorted(assets, key=lambda item: item["name"].lower())


@app.post("/api/effects")
async def upload_effect(file: UploadFile = File(...)):
    name = Path(file.filename or "effect.wav").name
    ext = Path(name).suffix.lower()
    if ext not in AUDIO_EXTENSIONS:
        raise HTTPException(415, "Upload WAV, MP3, OGG, M4A or AAC")
    eid = uuid.uuid4().hex
    target = EFFECTS / (eid + ext)
    total = 0
    try:
        with target.open("wb") as dest:
            while chunk := await file.read(1 << 20):
                total += len(chunk)
                if total > 50 * 1024**2:
                    raise HTTPException(413, "Sound effect must be under 50 MiB")
                dest.write(chunk)
        proc = subprocess.run([tool("ffprobe"), "-v", "error", "-select_streams", "a:0",
                               "-show_entries", "stream=codec_type", "-of", "csv=p=0", str(target)],
                              capture_output=True, text=True, timeout=30)
        if proc.returncode or "audio" not in proc.stdout:
            raise HTTPException(422, "Invalid sound file")
        (EFFECTS / (eid + ".json")).write_text(json.dumps({"name": name}, ensure_ascii=False), encoding="utf8")
        return {"id": eid, "name": name}
    except Exception:
        target.unlink(missing_ok=True)
        raise
    finally:
        await file.close()


@app.get("/api/effects/{eid}/media")
def effect_media(eid: str):
    if not re.fullmatch(r"[a-f0-9]{32}", eid):
        raise HTTPException(404, "Effect not found")
    try:
        return FileResponse(stored_effect(eid))
    except ValueError:
        raise HTTPException(404, "Effect not found") from None


def run_render(job_id: str, project: dict, edits: Edits, length: float) -> None:
    pid = project["id"]
    folder = project_dir(pid)
    output = folder / f"export-{job_id}.mp4"
    scratch = folder / f"render-{job_id}.filter"
    def status(**updates):
        with JOB_LOCK:
            JOBS[job_id].update(updates)
    try:
        filters = []
        for i, seg in enumerate(edits.segments):
            st, en = f"{seg.start:.6f}", f"{seg.end:.6f}"
            filters.append(f"[0:v]trim=start={st}:end={en},setpts=PTS-STARTPTS,{STYLE_FILTERS[edits.style]}[v{i}]")
            if project["has_audio"]:
                filters.append(f"[0:a]atrim=start={st}:end={en},asetpts=PTS-STARTPTS[a{i}]")
            else:
                filters.append(f"anullsrc=r=48000:cl=stereo,atrim=duration={seg.end-seg.start:.6f},asetpts=PTS-STARTPTS[a{i}]")
        inputs = "".join(f"[v{i}][a{i}]" for i in range(len(edits.segments)))
        filters.append(f"{inputs}concat=n={len(edits.segments)}:v=1:a=1[vout][abase]")
        args = [tool("ffmpeg"), "-hide_banner", "-nostdin", "-loglevel", "error", "-y", "-progress", "pipe:1",
                "-i", str(asset_path(project))]
        for effect in edits.effects:
            args.extend(["-i", str(stored_effect(effect.id))])
        if edits.effects:
            for idx, effect in enumerate(edits.effects, start=1):
                delay = round(effect.at * 1000)
                filters.append(f"[{idx}:a]aformat=sample_rates=48000:channel_layouts=stereo,volume={effect.volume:.3f},adelay={delay}|{delay}[fx{idx}]")
            labels = "[abase]" + "".join(f"[fx{i}]" for i in range(1, len(edits.effects)+1))
            filters.append(f"{labels}amix=inputs={len(edits.effects)+1}:duration=first:dropout_transition=0:normalize=0[aout]")
        else:
            filters.append("[abase]anull[aout]")
        scratch.write_text(";\n".join(filters), encoding="utf8")
        args.extend(["-filter_complex_script", str(scratch), "-map", "[vout]", "-map", "[aout]",
                     "-c:v", "libx264", "-preset", "veryfast", "-crf", "23", "-pix_fmt", "yuv420p",
                     "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", str(output)])
        with subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True) as proc:
            for line in proc.stdout:
                if line.startswith("out_time_ms="):
                    try:
                        seconds = int(line.split("=", 1)[1]) / 1_000_000
                        status(progress=min(99, round(seconds / length * 100)))
                    except (ValueError, ZeroDivisionError):
                        pass
            error = proc.stderr.read()[-1200:]
            code = proc.wait()
        if code != 0 or not output.exists():
            raise RuntimeError("FFmpeg render failed: " + error)
        status(state="done", progress=100)
    except Exception as exc:
        output.unlink(missing_ok=True)
        status(state="error", error=str(exc)[:700])
    finally:
        scratch.unlink(missing_ok=True)


@app.post("/api/projects/{pid}/render")
def render(pid: str, edits: Edits):
    project = load_project(pid)
    length = validate_edits(edits, project["duration"])
    # Persist final edits before long job, so a crash does not lose the work.
    project.update(edits.model_dump())
    save_project(project)
    with JOB_LOCK:
        if any(j["project_id"] == pid and j["state"] == "working" for j in JOBS.values()):
            raise HTTPException(409, "A render is already running for this project")
        job_id = uuid.uuid4().hex
        JOBS[job_id] = {"id": job_id, "project_id": pid, "state": "working", "progress": 0, "error": None}
    threading.Thread(target=run_render, args=(job_id, project, edits, length), daemon=True).start()
    return JOBS[job_id]


@app.get("/api/jobs/{job_id}")
def job_state(job_id: str):
    with JOB_LOCK:
        job = JOBS.get(job_id)
        if not job:
            raise HTTPException(404, "Render job not found")
        return dict(job)


@app.get("/api/jobs/{job_id}/download")
def download(job_id: str):
    with JOB_LOCK:
        job = JOBS.get(job_id)
        if not job or job["state"] != "done":
            raise HTTPException(404, "Export not ready")
    path = project_dir(job["project_id"]) / f"export-{job_id}.mp4"
    return FileResponse(path, filename="cutforge-export.mp4", media_type="video/mp4")


# A production Vite build is served by the same local API process.
FRONTEND_DIST = ROOT / "frontend"
if FRONTEND_DIST.exists():
    from fastapi.staticfiles import StaticFiles
    app.mount("/", StaticFiles(directory=FRONTEND_DIST, html=True), name="frontend")
