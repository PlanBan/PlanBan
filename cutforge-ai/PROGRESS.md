# CutForge AI — project checkpoints

Repository: `PlanBan/PlanBan`
Branch: `feat/cutforge-ai-mvp`
Project path: `cutforge-ai/`
Date started: 2026-10-25

## Goal
Local, browser-based editor with upload, automatic silence suggestions, nondestructive timeline, manual cuts, optional SFX and render/export via local FFmpeg.

## Checkpoints
- [x] Stage 0: locate an existing repository, create an isolated branch, write recovery notes.
- [ ] Stage 1: FastAPI backend, media validation, analysis, edits, effects and rendering.
- [ ] Stage 2: React browser editor with both automatic and manual workflows.
- [ ] Stage 3: automated tests, README, local smoke test, fixes.
- [ ] Stage 4 (future): Whisper transcript, smarter scene/audio cues, advanced transitions.

## Recovery / “продолжай”
1. Open this file and the branch history.
2. Check the latest commit and checkbox above; resume the earliest unchecked stage.
3. Run backend tests: `cd cutforge-ai && python -m pytest -q`.
4. Run front-end build: `cd cutforge-ai/frontend && npm ci && npm run build`.
5. Check end-to-end with a short synthetic video before claiming full success.
6. Update this checklist and commit after each tested stage; never change unrelated `audio-speed-batch/` data.

## Constraints
- App binds to 127.0.0.1 by default; no cloud upload.
- Original source video is not edited; JSON project holds changes.
- Automatic cuts must remain user-reviewable.
- No secret tokens in repository.
- User content stays in ignored local `data/`.
