# Media Batch Studio / audio-speed-batch

Current snapshot: **v10.0.0** (2026-10-06).

This is a local Node.js + FFmpeg app developed in ChatGPT for batch media creation. The user's local Windows project folder is typically `H:\KI YouTube\audio-speed-batch`; PowerShell may need `npm.cmd` instead of `npm` when execution policy blocks `npm.ps1`.

## Core features

- Batch audio speed change without changing pitch.
- Separate photo/audio upload; pairs matched by stem (`15.jpg` + `15.mp3`, numeric `001` equals `1`).
- One final MP4, each image lasting exactly as long as its matching audio.
- Drag-and-drop plus normal file picker.
- Visual per-frame editor with smooth 4x internal-canvas camera motion and effect strength 5/8/12/15%.
- Motion types: none, zoom in/out, pan left/right/up/down, cinematic left/right.
- AI Montage for photo + audio mode: AI selects motion per frame; user can review and override before render.
- AI Sound Designer for finished video: transcript + sampled frames + scene cuts + user editorial brief -> timestamp/effect/gain suggestions -> user previews/edits -> FFmpeg mixes the chosen SFX.
- Curated Kenney CC0 library plus project built-ins and optional user SFX.

## v10 SFX loudness changes

The user reported that AI commonly suggested gains around 14%, and the effects were nearly inaudible in the final narration mix. There were two causes: the suggested per-effect gain was too low, and the global SFX master defaulted to 75%, making a 14% suggestion effectively about 10.5% before source-file loudness differences.

v10 changes this behavior:

- `very_subtle` now has a 26% gain floor and 38% ceiling;
- `subtle` uses 32–46%;
- `balanced` uses 38–60%;
- calm/warm/documentary profile ceilings were raised so quiet styles can remain gentle without disappearing;
- the OpenAI JSON schema itself enforces the selected profile minimum, so the model cannot return whisper-quiet values below the floor;
- exact-count fallback SFX use the same audible floor;
- global SFX master defaults to 100% instead of 75%, with range 50–125%;
- individual effect sliders allow 10–80%;
- before the selected gain is applied, every SFX is normalized with FFmpeg `loudnorm=I=-18:TP=-2:LRA=7`, making percentages more consistent across different WAV/OGG source files.

Keep these audible floors unless the user explicitly requests a quieter mix. Do not revert the global master to 75%.

## v9 sound-design changes

The user reported that the visual AI montage works very well, but sound design still felt semantically wrong for calm English-language educational/explainer videos: sharp transition sounds, sci-fi/game-like beeps and heavy impacts damaged the warm 2D atmosphere. v9 therefore changes the AI Sound Designer from cut-driven selection to context/style-driven selection.

### Editorial brief UI

The AI Sound Designer accepts:

- sound style profile;
- SFX intensity;
- audience/language;
- optional full script or video description;
- optional sound notes / explicit bans.

Default profile is **calm educational / health**, default audience is **English**, and default intensity is **very subtle**.

### Sound profiles

Profiles currently available:

- `calm_educational`
- `warm_2d`
- `documentary`
- `playful_educational`
- `energetic`

Each profile has allowed categories, banned terms, preferred fallback categories and gain limits.

### Hard library filtering

For calm profiles the backend filters the built-in/CC0 library before sending it to OpenAI. This is intentional: prompt text alone was not reliable enough when the model could still see inappropriate effects.

The calm educational profile removes or excludes things such as laser/zap, sci-fi, explosions/crunch, heavy punch/metal, low boom, reverse/riser-like sounds, heavy bell/bong and similar aggressive options. User-provided custom SFX remain available because their presence is assumed to be intentional.

### New calm built-in SFX

v9 added locally bundled soft effects created specifically for restrained explainer videos:

- `air-soft.wav` — Air Soft
- `brush-soft.wav` — Soft Brush
- `paper-soft.wav` — Paper Soft
- `tap-soft.wav` — Soft Tap
- `chime-warm.wav` — Warm Chime
- `blip-soft.wav` — Soft Blip

These require no additional download and remain available even if the Kenney cache is unavailable.

### Context-first prompt behavior

OpenAI receives the user's script/description and sound notes alongside the transcript, scene cuts and sampled frames. The prompt explicitly says:

- narration and meaning are more important than cut frequency;
- a scene cut alone is not a reason to add sound;
- calm educational videos may leave most cuts silent;
- choose SFX that support semantics and atmosphere;
- avoid game/sci-fi/trailer/meme feeling when the selected profile is calm.

### Exact SFX count remains

The numeric exact-count control (1–120) remains. If OpenAI returns fewer than requested, calm profiles prefer speech/semantic points before scene cuts and fill only from the profile's soft palette. Energetic mode may still prioritize cut-driven accents.

## v8 visual behavior that must remain

- Smooth zoom/pan is calculated on an internal canvas 4× larger than output to reduce zoompan rounding jitter.
- AI Montage sends image previews in batches and writes decisions into the same editable per-frame settings used by the manual gallery.
- The manual frame editor remains available after AI analysis.

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
- For calm educational and warm 2D profiles, semantic/context fit is more important than marking scene cuts.
- Do not re-enable sci-fi/heavy SFX for calm profiles merely by changing prompt wording; preserve backend filtering.
- Prefer subtle camera motion and context-fitting SFX, but do not make SFX effectively inaudible.

## Dependencies

`express`, `multer`, `adm-zip`, `ffmpeg-static`; Node >=18. v10 adds no new npm dependency.