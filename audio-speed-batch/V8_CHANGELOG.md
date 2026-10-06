# Media Batch Studio v8 changelog

Date: 2026-10-06

## User-facing changes

- Replaced SFX presets with an exact numeric SFX count (1–120).
- AI is asked for exactly the selected count; local fallback completion guarantees the requested count when AI under-returns.
- Fixed zoom jitter by rendering `zoompan` on a 4× internal canvas.
- Added pan left/right/up/down and cinematic-left/right movements.
- Added AI Montage to the Photo + Audio workflow. It analyzes uploaded images in batches of 16, considers matching audio duration, and writes editable per-frame motion settings into the existing gallery.
- Manual gallery remains the final override point before rendering.

## Validation performed

- `node --check server.js` passes.
- `node --check public/app.js` passes.
- `package.json` and `sounds/cc0-manifest.json` parse as valid JSON.
- DOM ID audit found no missing `getElementById()` targets.
- All eight animated FFmpeg filter variants were rendered in a synthetic test with FFmpeg 7.1.5 without filter errors.

No new npm dependencies were added.