# Stage 4 — Chapter 1: Moosruinen

Completed: 2026-09-11
Target: Godot 4.7.2 stable

Stage 4 turns the exploration/battle prototypes into the first complete chapter of WURZELHERZ.

## Chapter route
`RootHall` → `WhisperGrove` → `KnightApproach` → `MossSanctum` → `MossAftermath`.

## World content
- `WhisperGrove.tscn`: Flüsterhain with route-sensitive NPC dialogue, lore and the collectible healing item `MOOSTEE`.
- `KnightApproach.tscn`: Ritterpfad, a boss-approach room with environmental storytelling and German inscriptions.
- `MossSanctum.tscn`: Moossanktuarium, the boss arena and post-boss gate.
- `MossAftermath.tscn`: Wurzelausgang, post-boss scene and hook toward Stage 5 / Glasgarten.
- Reusable `NpcTalker`, `ItemPickup` and `StoryGate` components are normal editor-editable Godot scenes.

## Boss — MOOSRITTER
- Enemy data: `scenes/battle/data/MossKnight.tres`.
- Visual: `scenes/battle/enemies/MossKnightVisual.tscn`.
- German dialogue throughout the encounter.
- ACT choices: `ERINNERUNG HÖREN` and `WAFFE SENKEN`.
- Mercy threshold: 3.
- Distinctive generic patterns: `walls`, `cross`, and `aimed`.
- The shared `BattleScene` was extended with reusable `walls` and `cross` pattern helpers rather than boss-only battle code.

## Route/inventory integration
- Boss and training encounter outcomes use GameState fight/mercy counters.
- Flüsterhain NPC dialogue can react to the current route.
- `MOOSTEE` is collected in-world and can be consumed from ITEM in battle for healing.
- Resolving the Moosritter sets `moosritter_resolved`; entering the aftermath sets `chapter1_complete`.

## Validation
Static validation: PASS with zero errors for `res://` references, TSCN/TRES `load_steps`, signal methods, required chapter files, boss data/pattern configuration and room connectivity.

Runtime note: the build environment still has no runnable Godot 4.7.2 binary, so engine-boot playtesting is not claimed.
