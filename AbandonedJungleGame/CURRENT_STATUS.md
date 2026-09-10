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
- Main menu is the project entry scene with exactly `PLAY` and `QUIT`.
- Menu has editable moving parallax mist and leaves plus lost-ruins layers.
- Player is a separate editable CharacterBody2D scene with Inspector movement/combat values and idle/walk/jump/attack/hurt/death animations.
- Free Kenney CC0 character art is stored locally.
- Animated Kenney CC0 bee enemy scene is complete with editable patrol/chase/HP/damage/score parameters.
- First real jungle level now replaces the placeholder.
- Level length is about 3600 px and contains editable ground segments, mossy stone platforms, ruin pillars, cracks and vines.
- Environment uses layered `Parallax2D` jungle, ruins, moving mist and foreground leaves.
- Player and five individually editable BeeEnemy instances are placed in the scene.
- HUD shows HP, score, objective text and controls.
- Game-over overlay has Restart and Main Menu buttons.
- Ordinary level geometry is stored directly in the `.tscn` scene; it is not generated procedurally by GDScript.

## Saving rule
Before starting each substantial step, inspect this file and `PROJECT_PLAN.md`. After every completed step, commit the actual project files to `AbandonedJungleGame/game/`, update this status, and only then continue.

## Asset research
Kenney's New Platformer Pack is used for player/enemy art and is CC0. Final source/license notes must be recorded in `game/docs/ASSET_LICENSES.md`.

## Next action
Add the collectible/objective and the level exit as their own editable scenes, place collectibles manually in JungleLevel, and make the exit activate when the objective is complete. Save that checkpoint before audio.
