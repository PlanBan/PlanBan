# CURRENT STATUS — Abandoned Jungle Game

Last checkpoint: 2026-09-10
Target engine: Godot 4.7.2

## Continuation rule
Read this file and `PROJECT_PLAN.md` before continuing. Work in `AbandonedJungleGame/game/`; do not restart from scratch. Save each substantial milestone before moving to the next one.

## Stable recovery
The old corrected Neon prototype remains in `legacy_neon_prototype/`. V1 jungle progress is also preserved by Git history and a local pre-V2 ZIP checkpoint.

## Current active version: V2
V2 was started after user feedback that V1 launched but had a weak visual style, crooked attack animation and unreliable jumps.

Completed V2 fixes:
- Godot 4.7.2 relic error fixed: `monitoring` is now changed with `set_deferred()` inside `body_entered`.
- Player art replaced with a dedicated jungle explorer set stored as separate editable SVG assets (`assets/characters/explorer_v2/`).
- Real `AnimatedSprite2D` idle/walk/jump/attack/hurt/death visual states are used instead of repeating one texture.
- Attack no longer rotates the whole player. A separate editable `WeaponPivot` contains a machete and attack arc; only the weapon swing is animated.
- Attack hitbox now moves to the actual facing side instead of staying on the right.
- Jump upgraded to `jump_velocity=-650`, `gravity=1600` with Inspector-editable values.
- Added coyote time, jump buffering and variable jump release for more reliable platforming.
- Player movement speed/acceleration and camera smoothing were tightened.

## Existing game systems retained
- Main menu with exactly `PLAY` and `QUIT`.
- Moving menu/background layers.
- 3600 px editor-built jungle/ruins level.
- Five enemies, HUD, damage/game over.
- Eight relics and an unlockable ancient gate with win screen.
- Local audio files and AudioStreamPlayer nodes exist in the working project and still need to be fully checkpointed/documented on GitHub.

## Editing philosophy
Level design, positions, visuals, weapon geometry, animations, props and UI should remain normal Godot scenes/nodes/resources editable in the Inspector. GDScript is only for behaviour.

## Next action
Continue V2 visual redesign: make the jungle/ruins scene and menu more cohesive and atmospheric, adjust platform heights for forgiving traversal, improve enemy presentation, then save another checkpoint. After that checkpoint audio binaries, licenses, validate references and produce the V2 ZIP.
