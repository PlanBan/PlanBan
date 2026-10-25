# CutForge AI — progress and recovery

**Project:** `cutforge-ai/` within repository `PlanBan/PlanBan`  
**Development branch:** `feat/cutforge-ai-mvp`  
**Started:** 2026-10-25

## Checkpoints

- [x] Stage 0 — Repo inspection, isolated development branch, checkpoint file.
- [x] Stage 1 — FastAPI: uploads, FFprobe validation, FFmpeg silence detector, editable project JSON, personal SFX, background MP4 export.
- [x] Stage 2 — Responsive HTML/CSS/JS studio: video preview, two working modes, timeline, clip split/delete, trim fields, editable pause recommendations, preset filters, personal sound library, progress/download.
- [x] Stage 3 — 3/3 automated backend integration tests passed. `node --check frontend/app.js` passed. Additional video-without-audio render passed. Static front routes HTTP 200.
- [ ] Stage 4 — Manual visual browser QA on user's machine and improvements based on feedback.
- [ ] Stage 5 — Transcript/Whisper, cinematic presets, smarter AI cues, transitions, drag-to-reorder, scaling for many clips.

## What is REALLY functional

Use `README.md` to install Python dependencies and FFmpeg, launch on `127.0.0.1:8000`, upload a video, analyze pauses, accept selected cuts, manually split/remove/trim segments, add custom audio, and export H.264/AAC MP4.

### Automated verification on 2026-10-25

- Full input -> upload -> silence analysis -> edit validation -> two-clip render -> MP4 download: **PASS**.
- Custom WAV upload -> sound overlay render: **PASS**.
- Invalid videos and path input: **PASS**.
- Video without source audio -> silent output audio: **PASS**.
- JS syntax and backend Python compilation: **PASS**.
- Static `index.html`, `app.css`, `app.js`: **HTTP 200**.
- Desktop/mobile static Chromium render tested; responsive 390px viewport has **no horizontal overflow**. UI mode toggle test passed with no JS exceptions.
- Full Playwright browser-to-local-server test blocked by environment network policy; real Chrome/Edge import and export QA remains for the user.
- GitHub Actions workflow for PR head `810e5bff` completed **SUCCESS** on 2026-10-25.

## Expected limitations / follow-up fixes

1. When previewing an edited timeline, HTML video element uses the original asset and skips cut sections. Validate behavior in Chrome/Edge with sample 1-hour footage.
2. User-supplied MKV/MOV formats may need proxy conversion for browser playback; FFmpeg imports can work even when browsers cannot play the codec.
3. The base engine is rule-based audio silence detection, not semantic AI; avoid claims of smart content understanding.
4. One global color preset; advanced keyframes/transitions and per-clip effects are future enhancements.
5. Background job state is in memory; interrupted render should be restarted. Saved project edits survive restart.
6. Intensive or numerous FFmpeg filter graph segments could make full-hour exports slower. Current limit 120 clips / 40 SFX.
7. Ensure account/private media security before remote public deployment; local host only.

## If the user says «продолжай»

1. Read this file **from the repository branch** and the latest commits / PR (not from conversation memory).
2. Check actual state in GitHub, including any tests and file changes. Resume from the earliest unchecked stage.
3. Make each meaningful improvement on this same branch with a descriptive Git commit; update this file.
4. Run `cd cutforge-ai && PYTHONPATH=. python -m pytest -q` and `node --check frontend/app.js` after editing.
5. Do not overwrite existing `audio-speed-batch/` files or unrelated repository content.
6. If a bug occurs: reproduce -> capture exact error -> add failing test -> fix -> rerun tests -> commit -> mark checkpoint.

**Next recommended action:** User opens local app and checks import/auto-cuts on a representative 5–10 minute video; then verify hour-long export and preview behavior. Finish visual QA and fix any issues before investing in Whisper.

## 2026-10-25 — Windows launcher repair (v0.1.1)

- User reported clicking Start did not open the app; exact Windows error not yet available.
- Replaced starter with diagnostics for incomplete ZIP extraction, Python 3.10+, FFmpeg+FFprobe, virtualenv setup, pip errors, and occupied localhost port.
- Added Windows troubleshooting file and root-level `START_CUTFORGE_WINDOWS.cmd`.
- Keeps terminal open after exit, prints actionable error messages; browser auto-opens after launch when available.
- Recheck on the user's Windows PC; Linux tests cannot emulate all Windows launcher behaviors.


## 2026-10-25 — Stage 6: Node.js runtime + private Cloudflare HTTPS

- [x] Dependency-free Node.js 20 HTTP backend, same local project JSON as Python, no Python/npm install required. FFmpeg + ffprobe are still required for media tasks.
- [x] Chunked 8 MiB uploads to work with Cloudflare request-size limits; local streaming prevents whole-video buffering in RAM.
- [x] Local FFmpeg silence analysis, nondestructive manual edits, personal WAV/MP3/etc SFX, background H.264/AAC render, progress status, HTTP Range serving.
- [x] Frontend auto-switches upload method depending on `/api/health` Node vs Python engine; earlier Python mode is retained.
- [x] Security defaults: binds to 127.0.0.1, Host allowlist, same-origin mutation requests, explicit public hostname opt-in; Cloudflare Access mandatory for a public hostname.
- [x] Node integration tests: 2/2 pass (includes upload/analyze/edit/export and SFX on silent footage), JS syntax check passed.
- [ ] Need real Windows launch test and user Cloudflare domain/Access configuration; no public site was deployed.
- [ ] For long remote analyses: move silence detection to background jobs to avoid edge timeouts.
- [ ] Large video downloads through public Cloudflare routes have service-specific conditions; local use or private network is preferable.

**If user says `продолжай`**: check GitHub branch `feat/cutforge-ai-mvp`, inspect this section, run `cd cutforge-ai/node-server && node --test`, confirm Cloudflare Access gate before changing any public tunnel configuration, and fix the next uncompleted checkpoint.