# SFX sources and licenses

Media Batch Studio v7 uses a curated selection from free **Kenney** audio asset packs.

## Upstream packs

- **Interface Sounds** — https://kenney.nl/assets/interface-sounds — Creative Commons CC0
- **Impact Sounds** — https://kenney.nl/assets/impact-sounds — Creative Commons CC0
- **Sci-Fi Sounds** — https://kenney.nl/assets/sci-fi-sounds — Creative Commons CC0
- **UI Audio** — https://kenney.nl/assets/ui-audio — Creative Commons CC0 (reference pack for possible future additions)

Kenney's support page states that assets on its asset pages are public-domain licensed (CC0), may be used in commercial projects, and attribution is not required.

## Programmatic cache source

For convenient per-file downloads, the local app's curated manifest points to the public GitHub repository/index:

`Mcamento8/open-game-sfx-index`

Raw files are cached by the local app under:

`sounds/cache/kenney-cc0`

The original small built-in WAV effects remain as an offline fallback. The application should gracefully continue if the remote CC0 cache cannot be downloaded.

## Timing behavior

The local v7 renderer does not simply delay a sound to the AI timestamp. It analyzes each chosen SFX and estimates its main transient/peak, then shifts the sound so the main hit aligns with the target edit moment. Scene changes are independently detected with FFmpeg and supplied to AI as precise candidate timestamps.
