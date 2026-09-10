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
- `scenes/menu/MainMenu.tscn` is the project entry scene.
- Main menu contains exactly two primary buttons: `PLAY` and `QUIT`.
- `PLAY` changes to `scenes/levels/JungleLevel.tscn`; `QUIT` exits.
- Menu visuals are separate editable nodes/assets.
- Moving menu background uses `Parallax2D` with editable autoscroll mist and leaves.
- Abandoned jungle / lost temple visual direction is established.
- Player is a separate editable `CharacterBody2D` scene with `AnimatedSprite2D`, `AnimationPlayer`, collision shape, attack area, slash effect and camera.
- Player movement/combat values are exported to the Inspector.
- Player has editable idle/walk/jump/attack/hurt/death animations.
- Free Kenney character art is stored locally under `assets/characters/`.
- First enemy milestone is complete: `scenes/enemies/BeeEnemy.tscn` is a separate editable enemy scene.
- Bee uses two free Kenney CC0 animation frames stored locally as `assets/enemies/bee_a.svg` and `bee_b.svg`.
- Bee patrol/chase speed, range, HP, damage and score value are Inspector-editable exports.
- Bee has flying, hurt and death animations plus a visible editable damage area.
- Player is registered in the `player` group so enemies can discover it without hard-coded scene paths.

## Target direction
An editable 2D abandoned-jungle / lost-ruins platformer. Prefer `.tscn`, `AnimatedSprite2D`, `AnimationPlayer`, `AudioStreamPlayer`, `CollisionShape2D`, `TileMapLayer`, reusable props and Inspector values. Keep GDScript only for gameplay logic.

## Saving rule
Before starting each substantial step, inspect this file and `PROJECT_PLAN.md`. After every completed step, commit the actual project files to `AbandonedJungleGame/game/`, update this status, and only then continue.

## Asset research
Kenney's New Platformer Pack is used for the player and bee enemy and is CC0. Final source/license notes must be recorded in `game/docs/ASSET_LICENSES.md`.

## Next action
Replace the temporary `JungleLevel.tscn` with the first playable abandoned-jungle / ruins level using editable scene nodes and reusable platform/prop scenes. Place Player and several BeeEnemy instances. Save the level milestone before adding collectible/objective and exit logic.
