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
- Player milestone is now saved: `scenes/player/Player.tscn` is a separate editable `CharacterBody2D` scene with `AnimatedSprite2D`, `AnimationPlayer`, collision shape, attack area, slash effect and camera.
- Player movement/combat values are exported to the Inspector: speed, acceleration, friction, jump, gravity, dash, HP, attack timing/damage, invulnerability and respawn values.
- Player has editable Godot animations for idle breathing, walk bob/tilt, jump squash/stretch, attack, hurt flash/shake and death fall/fade.
- Free Kenney New Platformer Pack character art is stored locally as `assets/characters/explorer_idle.png`.

## Target direction
An editable 2D abandoned-jungle / lost-ruins platformer. Prefer `.tscn`, `AnimatedSprite2D`, `AnimationPlayer`, `AudioStreamPlayer`, `CollisionShape2D`, `TileMapLayer`, reusable props and Inspector values. Keep GDScript only for gameplay logic.

## Saving rule
Before starting each substantial step, inspect this file and `PROJECT_PLAN.md`. After every completed step, commit the actual project files to `AbandonedJungleGame/game/`, update this status, and only then continue.

## Asset research
Kenney's New Platformer Pack is used for the player and is CC0. Enemy art from the same pack is the next asset milestone. Final source/license notes must be recorded in `game/docs/ASSET_LICENSES.md`.

## Next action
Add the first enemy as a separate editable scene using free Kenney enemy art and animation. Then save that enemy milestone before replacing the temporary JungleLevel with the playable jungle/ruins level.
