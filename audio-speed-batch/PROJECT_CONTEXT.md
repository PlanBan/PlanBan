# Media Batch Studio / audio-speed-batch

Current snapshot: **v7.0.0** (2026-10-06).

This is a local Node.js + FFmpeg app developed in ChatGPT for batch media creation. The user's local Windows project folder is typically `H:\KI YouTube\audio-speed-batch` and PowerShell should use `npm.cmd` rather than `npm` when execution policy blocks `npm.ps1`.

## Current features

- Batch audio speed change without changing pitch.
- Separate photo and audio upload areas; pairs matched by numeric/name stem (`15.jpg` + `15.mp3`, `001.mp3` treated like `1`).
- Builds one final MP4, holding each image for the duration of its matching audio.
- Drag-and-drop for images/audio, plus normal file picker.
- Visual per-frame gallery: each uploaded image can independently use no motion, zoom-in, or zoom-out, with strength 5/8/12/15%.
- Optional fade-in at the beginning and fade-out at the end of the final video.
- AI Sound Designer tab: final video + optional custom SFX -> OpenAI analysis -> suggested timestamp/effect/gain -> user previews and confirms -> FFmpeg mixes final MP4.
- OpenAI API key is not intended to be persisted by the app; it can be entered for the request or supplied as `OPENAI_API_KEY`.

## v7 sound-design changes

The user reported that some effects felt late or did not land on the expected edit beat. v7 therefore adds two separate timing improvements:

1. **Scene-cut detection.** FFmpeg scans the source video with the `scene` metric and extracts precise scene-change timestamps. These timestamps are passed to the AI prompt, and transition/impact suggestions are instructed to use exact edit points instead of approximate sampled-frame times.
2. **SFX transient alignment.** Before final mixing, FFmpeg decodes the chosen SFX to low-rate mono PCM. The app analyzes short RMS windows to estimate the main transient/peak. The SFX start is shifted so its important hit lands on the target timestamp. Whoosh/riser-like sounds align their peak; sharp one-shots bias toward the onset of the main transient.

For transition-like categories (`whoosh`, `riser`, `transition`, `impact`) the renderer may also snap an AI suggestion to a nearby detected scene cut (within a small tolerance).

## CC0 sound library

v7 adds a curated manifest of Kenney CC0 effects from these packs:

- Kenney Interface Sounds
- Kenney Impact Sounds
- Kenney Sci-Fi Sounds

The local app keeps its original small built-in fallback library. On the first AI analysis, it attempts to download curated CC0 files from the public GitHub index/mirror `Mcamento8/open-game-sfx-index` and caches them under `sounds/cache/kenney-cc0`. If network download fails, AI can still use local built-ins and user-provided SFX.

The v7 local manifest contains 25 selected effects: multiple UI clicks, light accents, punch/metal/bell/soft impacts, crunchy impacts, low booms, and short electronic zaps. Do not remove the fallback built-ins.

## Important implementation notes for future versions

- Keep all non-AI audio/video processing local.
- Never automatically add AI effects before the user can preview/confirm them.
- Preserve per-frame visual settings rather than reverting to comma-separated frame numbers.
- Preserve drag-and-drop prevention at the page level so dropped files do not open in browser tabs.
- Prefer a diverse SFX library; avoid repeating the same sound for adjacent suggestions.
- For scene transitions, timing accuracy is more important than merely selecting a semantically related sound.
- Keep source/license documentation in `SFX_SOURCES.md` and the local `sounds/cc0-manifest.json`.

## Current Node dependencies

`express`, `multer`, `adm-zip`, `ffmpeg-static`. Node >=18. No new npm dependency was required for v7; Node's built-in `fetch` is used for CC0 caching.
