# CURRENT STATUS — Abandoned Jungle Game

Last checkpoint: 2026-09-10
Target engine: Godot 4.7.2

## Important continuation instruction
If work is interrupted, read this file and `PROJECT_PLAN.md` first, then continue from the first unchecked milestone. Do not restart the project from scratch.

## What exists right now
The currently playable checkpoint is the corrected **Neon Courier** prototype. It is stored in `legacy_neon_prototype/` so no working progress is lost.

Current prototype features:
- 2D platformer movement;
- jump;
- dash;
- melee attack;
- 3 HP and damage/knockback;
- patrolling/chasing enemies;
- 10 collectibles;
- score;
- locked exit until all collectibles are gathered;
- win/lose overlay;
- basic main menu;
- compatibility fix for Godot 4.7.2 (`draw_ellipse` conflict fixed).

## User's new direction — this is the target
Rebuild the prototype into an **abandoned jungle / lost ruins** game.

The final project should be easy to edit manually in the Godot editor. Prefer Godot scenes, nodes, resources, AnimationPlayer/AnimatedSprite2D, TileMap/TileMapLayer, exported properties and inspector-editable values instead of generating most visuals and level content from GDScript.

Required direction:
- start menu with exactly `Play` and `Quit` buttons;
- animated/moving jungle menu background;
- abandoned jungle atmosphere with ruins;
- free-to-use character assets;
- free-to-use enemy assets;
- walk/idle/jump/attack/hurt/death animations where suitable assets allow it;
- sound effects and ambient/music audio using assets with suitable licenses;
- assets stored locally in the project so it works offline;
- clear attribution/license notes for every external asset pack;
- scenes/resources organized so the user can change them visually in Godot.

## Current external asset research
A free Kenney platformer character set was located on GitHub (`eturner58/game-assets`, New Platformer Pack). Character idle/walk images have been verified as accessible. Before final use, verify the upstream license/attribution information and copy that into `ASSET_LICENSES.md`.

## Next action
1. Keep `legacy_neon_prototype/` untouched as a recovery checkpoint.
2. Create a new Godot project structure in `game/` built around editable `.tscn` scenes rather than code-generated visuals.
3. Add menu scene (`Play`, `Quit`) with moving jungle background.
4. Add locally stored free sprite assets and animations.
5. Build first jungle level and enemies.
6. Add audio.
7. Test/validate Godot 4.7.2 project structure and export a ZIP checkpoint.
