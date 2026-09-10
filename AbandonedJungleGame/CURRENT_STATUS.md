# CURRENT STATUS — Abandoned Jungle Game

Last checkpoint: 2026-09-10
Target engine: Godot 4.7.2

## Important continuation instruction
If work is interrupted, read this file and `PROJECT_PLAN.md` first, then continue from the first unchecked milestone. Do not restart the project from scratch.

## What exists right now
The corrected Neon Courier prototype is preserved in `legacy_neon_prototype/` as a recovery checkpoint.

A new editable Godot project structure has now been created locally in `/mnt/data/jungle_ruins_ready` and is being mirrored to `AbandonedJungleGame/game/` on GitHub. It contains `project.godot`, icon, editing README, and dedicated folders for scenes, scripts, assets, resources and docs.

## Target direction
Rebuild the prototype into an **abandoned jungle / lost ruins** game that is easy to edit manually in Godot.

Use Godot scenes/resources for ordinary content: `.tscn`, `AnimatedSprite2D`, `AnimationPlayer`, `AudioStreamPlayer`, `CollisionShape2D`, `TileMapLayer`, reusable props and inspector-editable exported values. Keep GDScript only for gameplay logic that genuinely needs code.

Required direction:
- start menu with exactly `Play` and `Quit` buttons;
- animated/moving jungle menu background;
- abandoned jungle atmosphere with ruins;
- free-to-use character and enemy assets stored locally;
- walking/idle/jump/attack/hurt/death animations where suitable assets allow;
- sound effects and jungle ambience/music;
- clear asset/license notes;
- compatibility target Godot 4.7.2.

## Saving rule
Before starting any substantial step, inspect this file and `PROJECT_PLAN.md`. After every completed step, save the actual project files to `AbandonedJungleGame/game/` in the same GitHub repository, update this status, and only then continue.

## Asset research
Kenney's New Platformer Pack is confirmed on Kenney's official site as Creative Commons CC0 and contains 440 files. Character idle/walk art is accessible from the public `eturner58/game-assets` mirror. External assets will be copied into the project and documented in `docs/ASSET_LICENSES.md`.

## Completed this session
- Created fresh editable `game/` folder structure without deleting the working legacy prototype.
- Moved input definitions into `project.godot` instead of creating them dynamically at runtime.

## Next action
Create `scenes/menu/MainMenu.tscn` with `Play` and `Quit` buttons, plus editable moving jungle background layers. Save that milestone to GitHub before continuing to the player scene.
