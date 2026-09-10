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
- First real 3600px jungle/ruins level is complete with editable ground, mossy stone platforms, ruin pillars, moving parallax jungle/mist/leaves, Player and five BeeEnemy instances.
- HUD shows HP, score, objective and controls; Game Over overlay provides restart/menu.
- Objective milestone is complete: `scenes/props/Relic.tscn` is an editable animated floating collectible.
- Eight Relic instances are manually placed in `JungleLevel.tscn`, so their positions can be changed directly in the editor.
- `scenes/props/ExitTemple.tscn` is an editable animated ancient gate with SEALED/OPEN states.
- Collecting every relic activates the gate; entering it shows a Win overlay with Play Again/Main Menu.
- Ordinary level geometry and collectible placement are stored directly in `.tscn` scenes rather than procedurally generated.

## Saving rule
Before starting each substantial step, inspect this file and `PROJECT_PLAN.md`. After every completed step, commit the actual project files to `AbandonedJungleGame/game/`, update this status, and only then continue.

## Asset research
Kenney's New Platformer Pack is used for player/enemy art and is CC0. Final source/license notes must be recorded in `game/docs/ASSET_LICENSES.md`.

## Next action
Add audio as editable `AudioStreamPlayer` nodes/resources: menu UI feedback, jump/attack/hurt/collect/exit SFX, plus a looping jungle ambience. Save the audio checkpoint before license/validation/final ZIP.
