# V10 Changelog — Audible AI SFX

Date: 2026-10-06

## Problem

AI often suggested SFX gains around 14%, which were almost inaudible under narration. The global SFX master also defaulted to 75%, so a 14% suggestion was effectively mixed at about 10.5%. Different source WAV/OGG files also had very different native loudness.

## Changes

- Very subtle mode: 26–38%.
- Soft mode: 32–46%.
- Balanced mode: 38–60%.
- OpenAI schema enforces the selected minimum gain.
- Exact-count fallback effects use the same audible floor.
- Global SFX master now defaults to 100% and allows 50–125%.
- Individual SFX sliders allow 10–80%.
- Each SFX is normalized before gain with FFmpeg `loudnorm=I=-18:TP=-2:LRA=7`.
- v9 semantic/context filtering and calm sound palette remain unchanged.

## Validation

- `node --check server.js` passed.
- `node --check public/app.js` passed.
- New loudnorm + gain chain passed an FFmpeg test on bundled `air-soft.wav`.
- A synthetic video + narration + SFX full mix produced a valid H.264/AAC MP4.
