# CURRENT STATUS — Abandoned Jungle Game

Last checkpoint: 2026-09-10
Target engine: Godot 4.7.2 stable
Active checkpoint: **Abandoned Jungle Ruins V2**

## Continuation instruction
Read this file, `PROJECT_PLAN.md`, `game/docs/V2_CHANGES.md`, `game/docs/VALIDATION_REPORT.md` and `checkpoints/V2_2026-09-10_MANIFEST.txt` before changing the project. Continue from V2; do not restart from the old Neon prototype.

## V2 completed in this checkpoint
- Reworked the visual direction toward darker abandoned jungle / lost temple ruins.
- Replaced the old player presentation with an explorer sprite set.
- Reworked melee so the machete/attack arc swings independently instead of rotating the whole character.
- Attack hitbox follows the facing direction.
- Jump velocity increased; coyote time and jump input buffering added.
- Level platform heights were normalized/lowered so the intended route is reachable.
- Fixed the Godot 4.7 `Area2D.monitoring` physics-lock error on relic pickup.
- Exit gate monitoring is also deferred, preventing the same error when the last relic opens the gate.
- Bee hurt animation returns to fly; death collision disabling is deferred safely.
- Game Over/Win freeze active enemies behind the overlay.
- Main-menu rapid double actions are blocked and PLAY gets keyboard focus.
- Editable SFX and looping jungle ambience were added to the packaged V2 project.
- Asset/license notes and validation report were added.

## Validation/package
Final user package: `Abandoned_Jungle_Ruins_V2_Godot_4.7.2.zip`
SHA256: `876af92bb5c8a5fc02258473586b2cdbb7305cf6c54587d10554a281ed89717f`

Pre-package checks passed with zero project errors: `res://` targets, TSCN resource ids/load steps, menu buttons, SVG parsing, WAV validity, Vorbis OGG probe, known deferred-monitoring guards, and a fresh ZIP extraction/recheck. `unzip -t` also reports no errors.

Important limitation: the build container does not contain a runnable Godot 4.7.2 editor executable, so this checkpoint was not engine-boot playtested inside the container. Do not claim otherwise.

## GitHub persistence
Updated V2 gameplay scripts, redesigned menu scene, V2 environment layers, documentation and a complete SHA256 manifest are saved in this repository. The manifest is the checksum record for the exact user-delivered V2 ZIP contents. The final ZIP itself is delivered through the conversation artifact.

## Next action
User playtests the V2 ZIP in Godot 4.7.2. If any runtime error or visual/gameplay problem is reported, patch this V2 checkpoint rather than rebuilding from scratch, then issue a new numbered ZIP and update this status again.
