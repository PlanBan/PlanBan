# Media Batch Studio / audio-speed-batch

Current snapshot: **v8.0.0** (2026-10-06).

This is a local Node.js + FFmpeg app developed in ChatGPT for batch media creation. The user's local Windows project folder is typically `H:\KI YouTube\audio-speed-batch`; PowerShell may need `npm.cmd` instead of `npm` when execution policy blocks `npm.ps1`.

## Core features

- Batch audio speed change without changing pitch.
- Separate photo/audio upload; pairs matched by stem (`15.jpg` + `15.mp3`, numeric `001` equals `1`).
- One final MP4, each image lasting exactly as long as its matching audio.
- Drag-and-drop plus normal file picker.
- Visual per-frame editor with effect strength 5/8/12/15%.
- Optional fade-in at the beginning and fade-out at the end.
- AI Sound Designer for finished video: transcript + sampled frames + scene cuts -> timestamp/effect/gain suggestions -> user previews/edits -> FFmpeg mixes the chosen SFX.
- Curated Kenney CC0 library plus project built-ins and optional user SFX.

## v8 changes requested by the user

### 1. Exact SFX count

The old preset selector (8/12/20/30 etc.) is removed. The AI Sound Designer now uses a numeric field **“Сколько SFX поставить”** and accepts 1–120. The model is explicitly asked for exactly that count. If it returns fewer, the app fills missing entries using detected scene cuts, speech-segment endings, and finally evenly spaced fallback points so the result count matches the requested number. The user can still uncheck entries before rendering.

### 2. Smooth photo zoom / no jitter

The user reported visible shaking during zoom. The cause was FFmpeg `zoompan` coordinate rounding when motion was calculated directly on the final-resolution canvas. v8 renders motion on an internal canvas **4× larger than the target resolution** and then outputs the final size. This strongly reduces one-pixel center jumps. Keep this high-resolution motion approach in future versions unless replacing `zoompan` with an equivalently smooth method.

### 3. More visual motion effects

Per-frame effect types now include:

- `none`
- `zoomIn`
- `zoomOut`
- `panLeft`
- `panRight`
- `panUp`
- `panDown`
- `cinematicLeft`
- `cinematicRight`

The last two are restrained zoom-in variants biased toward the left/right side of the composition.

### 4. AI Montage for photo + audio mode

The “Фото + аудио” section has an **AI-анализ монтажа** button. It sends the uploaded images to OpenAI in batches of 16 after local 512×512 preview generation. The model sees each frame plus the duration of its matching audio and chooses one of the supported motion types and 5/8/12/15% strength. AI results are written into the same `frameEffectSettings` used by the manual gallery, so the user can inspect and override every decision before rendering.

AI montage intentionally keeps a meaningful share of frames static (prompt target about 20–40%) to avoid constant motion.

## v7 timing behavior that must remain

- FFmpeg scene-cut detection provides precise edit timestamps.
- Transition-like SFX can snap to a nearby detected scene cut.
- SFX transient/peak alignment shifts each sound so its perceptual hit lands on the target timestamp.
- Whoosh/riser effects align near their peak; sharp one-shots bias toward transient onset.

## Sound library

The curated manifest includes selected Kenney CC0 effects from Interface Sounds, Impact Sounds, and Sci-Fi Sounds. They are cached under `sounds/cache/kenney-cc0` on first use. If the download fails, project built-ins and user-provided SFX remain available. Keep license/source documentation in `SFX_SOURCES.md` and `sounds/cc0-manifest.json`.

## Implementation rules for future versions

- Keep non-AI media processing local.
- Do not persist the user's OpenAI API key.
- Preserve the manual per-frame gallery and drag-and-drop behavior.
- AI montage may auto-fill visual settings because the user explicitly triggers it, but the settings must remain editable before final render.
- AI Sound Designer must still let the user preview/uncheck/change SFX before final mixing.
- Prefer subtle camera motion; avoid visual movement on every frame.
- For scene transitions, timing accuracy is more important than only semantic SFX matching.

## Dependencies

`express`, `multer`, `adm-zip`, `ffmpeg-static`; Node >=18. v8 adds no new npm dependency.