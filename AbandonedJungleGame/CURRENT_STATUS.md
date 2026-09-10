# CURRENT STATUS — Abandoned Jungle Game

Last checkpoint: 2026-09-10
Target engine: Godot 4.7.2

## Important continuation instruction
If work is interrupted, read this file and `PROJECT_PLAN.md` first, then continue from the first unchecked milestone. Do not restart the project from scratch.

## What exists right now
The corrected Neon Courier prototype is preserved in `legacy_neon_prototype/` as a recovery checkpoint.

The active rebuild is in `AbandonedJungleGame/game/` and locally in `/mnt/data/jungle_ruins_ready`.

## Completed active rebuild milestones
- Editable Godot folder structure created.
- Input actions are stored in `project.godot` rather than generated at runtime.
- `scenes/menu/MainMenu.tscn` is now the project entry scene.
- Main menu contains exactly two primary buttons: `PLAY` and `QUIT`.
- `PLAY` changes to `scenes/levels/JungleLevel.tscn`; `QUIT` exits.
- Menu visuals are built from separate editable Godot nodes/assets rather than procedural drawing code.
- Moving menu background uses `Parallax2D` nodes with editable `autoscroll` values: drifting mist and leaves.
- Abandoned jungle / lost temple visual direction is established in the menu.
- A temporary JungleLevel scene exists only so Play has a valid destination; it will be replaced with the actual level.

## Target direction
An editable 2D abandoned-jungle / lost-ruins platformer. Prefer `.tscn`, `AnimatedSprite2D`, `AnimationPlayer`, `AudioStreamPlayer`, `CollisionShape2D`, `TileMapLayer`, reusable props and Inspector values. Keep GDScript only for gameplay logic.

## Saving rule
Before starting each substantial step, inspect this file and `PROJECT_PLAN.md`. After every completed step, commit the actual project files to `AbandonedJungleGame/game/`, update this status, and only then continue.

## Asset research
Kenney's New Platformer Pack is confirmed on Kenney's official site as Creative Commons CC0. External assets copied into the project must be documented in `game/docs/ASSET_LICENSES.md`.

## Next action
Add the player as its own editable `CharacterBody2D` scene with `AnimatedSprite2D`, collision nodes, attack area/camera and exported movement/combat values. Use free Kenney character art stored locally. Then save that player milestone before starting enemies.
