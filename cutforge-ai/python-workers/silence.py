"""Streaming Python/FFmpeg silence detector. Standard library only; prints JSON on stdout."""
import json
import math
import re
import subprocess
import sys

START = re.compile(r"silence_start:\s*([\d.]+)")
END = re.compile(r"silence_end:\s*([\d.]+)")

def scan(path, threshold, min_pause, duration, ffmpeg="ffmpeg"):
    if not (math.isfinite(threshold) and -65 <= threshold <= -15 and
            math.isfinite(min_pause) and .2 <= min_pause <= 10 and
            math.isfinite(duration) and duration > 0):
        raise ValueError("Invalid silence detection arguments")
    cmd = [ffmpeg, "-hide_banner", "-nostdin", "-i", path, "-vn", "-af",
           f"silencedetect=noise={threshold}dB:d={min_pause}", "-f", "null", "-"]
    suggestions = []
    start = None
    tail = []
    proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE,
                            text=True, errors="replace")
    try:
        for line in proc.stderr:
            a = START.search(line)
            b = END.search(line)
            if a:
                start = float(a.group(1))
            if b and start is not None:
                end = min(duration, float(b.group(1)))
                if end - start >= min_pause:
                    suggestions.append({"start": round(start, 3), "end": round(end, 3)})
                start = None
            if len(tail) >= 12:
                tail.pop(0)
            tail.append(line.strip())
        code = proc.wait()
    finally:
        if proc.poll() is None:
            proc.kill()
            proc.wait()
    if code != 0:
        raise RuntimeError("FFmpeg analysis failed: " + " ".join(tail)[-700:])
    if start is not None and duration - start >= min_pause:
        suggestions.append({"start": round(start, 3), "end": round(duration, 3)})
    return suggestions

def main(argv):
    if argv == ["--self-test"]:
        assert START.search("silence_start: 1.25")
        assert END.search("silence_end: 1.75 | silence_duration: 0.5")
        print("Python silence worker: OK")
        return
    if len(argv) != 4 and len(argv) != 5:
        raise ValueError("usage: silence.py input threshold min_pause duration [ffmpeg]")
    path, db, seconds, duration = argv[:4]
    results = scan(path, float(db), float(seconds), float(duration), argv[4] if len(argv)==5 else "ffmpeg")
    print(json.dumps({"suggestions": results, "note": f"Found {len(results)} silence regions"}))

if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except Exception as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
