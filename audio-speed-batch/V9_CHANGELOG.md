# V9 Changelog — Context-aware AI Sound Designer

Date: 2026-10-06

## Why v9 exists

Visual AI montage was producing useful, logical camera movement, but SFX selection was too cut-driven and too aggressive for calm educational/explainer content. Sounds such as sharp zaps, sci-fi accents, heavy booms and game-like transitions could be technically synchronized yet editorially wrong.

## New UI inputs

The AI Sound Designer now includes:

- Style profile
- SFX intensity
- Audience/language
- Script or video description
- Sound notes / explicit bans
- Existing exact SFX count remains

Default preset: **Calm educational / health + Very subtle + English**.

## Style profiles

- Calm educational / health
- Warm 2D explainer
- Calm documentary
- Soft playful educational
- Energetic YouTube

## Backend filtering

Calm profiles filter the sound library before OpenAI sees it. The calm educational profile blocks aggressive/futuristic terms and categories including laser/zap, sci-fi, explosion/crunch, heavy punch/metal, low boom, riser/reverse transitions, heavy bell/bong and project heavy impact.

Custom user SFX are kept available.

## New bundled calm effects

- Air Soft (`air-soft.wav`)
- Soft Brush (`brush-soft.wav`)
- Paper Soft (`paper-soft.wav`)
- Soft Tap (`tap-soft.wav`)
- Warm Chime (`chime-warm.wav`)
- Soft Blip (`blip-soft.wav`)

These are local project assets and do not depend on GitHub downloads.

## AI prompt behavior

The model is told to treat the script/description as an editorial brief. Transcript, sampled frames and scene cuts remain available, but a scene cut by itself is explicitly not enough reason to add SFX. Narration clarity and semantic relevance are prioritized.

For calm modes, gain is capped much lower. If exact-count fallback is needed, the app prefers speech endpoints before scene cuts and uses the profile's soft filler palette.

## Compatibility

No new npm dependencies. Existing v8 visual AI montage and smooth 4× internal-canvas zoom/pan behavior remain unchanged.