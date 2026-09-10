# CURRENT STATUS — Abandoned Jungle Game

Last checkpoint: 2026-09-10 11:20 (+02:00)
Target engine: Godot 4.7.2

## Mandatory continuation rule
Before doing ANY new work, read `WORKFLOW.md`, this file, and `PROJECT_PLAN.md`. Continue the unfinished milestone. Do not restart the project from scratch unless the user explicitly asks for a reset.

## What I verified after the interrupted work
I inspected the actual local working directories (`/mnt/data/jungle_build` and `/mnt/data/jungle_work`). They contain the same files and are still essentially the corrected Neon Courier prototype. The only later local change is the README timestamp/content checkpoint; the abandoned-jungle conversion itself had NOT yet been implemented before the interruption.

A fresh local ZIP snapshot was created from the exact current `jungle_build` directory:
- `AbandonedJungleGame_WIP_2026-09-10_1120.zip`
- SHA256: `b9a62b962dab810a7a6f2d5e447588b99c993211fb1e64c57150732e42a34388`
- ZIP integrity check passed.

## Stable recovery checkpoint
The currently playable baseline is the corrected **Neon Courier** prototype under `legacy_neon_prototype/`.

Baseline features:
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

## Target requested by the user
Rebuild the prototype into an **abandoned jungle / lost ruins** game.

The final project must be easy to edit manually in Godot. Prefer Godot scenes, nodes, resources, AnimationPlayer/AnimatedSprite2D, TileMap/TileMapLayer, exported properties and inspector-editable values instead of generating most visuals and level content from GDScript.

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

## External asset research already done
A free Kenney platformer character set was located on GitHub (`eturner58/game-assets`, New Platformer Pack). Character idle/walk images were verified as accessible. Before final use, verify the upstream license/attribution information and record it in `ASSET_LICENSES.md`.

## Exact next action
1. Save the just-created WIP ZIP into GitHub `checkpoints/`.
2. Create the editable Godot folder structure under `game/`.
3. Commit that structure immediately as its own checkpoint.
4. Create `MainMenu.tscn` with `Play` and `Quit` and a moving jungle background.
5. Commit menu milestone immediately before moving on.
6. Then add local licensed character/enemy assets and animations, committing after each logical step.
