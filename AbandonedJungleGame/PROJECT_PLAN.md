# PROJECT PLAN — Abandoned Jungle Game

Target engine: Godot 4.7.2

## Goal
Turn the existing prototype into an editable 2D abandoned-jungle platformer using Godot scenes/resources and free licensed assets.

## Milestones
- [x] Preserve the last working Neon Courier prototype as a recovery checkpoint.
- [x] Document current status and continuation rules.
- [x] Create editable Godot folder structure under `game/`.
- [x] Create `MainMenu.tscn` with Play and Quit buttons.
- [x] Add animated/moving jungle background to the menu.
- [x] Add player scene with `AnimatedSprite2D` and inspector-editable gameplay values.
- [x] Add player idle/walk/jump/attack/hurt/death presentation.
- [x] Add enemy scene(s) using free sprite assets and animations.
- [x] Build first abandoned-jungle/ruins level with editable scene nodes.
- [x] Add collectible/objective and level exit.
- [x] Add sound effects for UI, footsteps/jump/attack/hurt/collect/exit.
- [x] Add looping jungle ambience.
- [x] Create `ASSET_LICENSES.md` with source/license details.
- [x] Perform static/structural Godot 4.7.2 compatibility validation.
- [x] Build a ready-to-import V2 ZIP checkpoint and verify ZIP integrity/fresh extraction.
- [x] Update `CURRENT_STATUS.md` and exact-file SHA256 manifest for V2.

## V2 quality pass completed
- [x] Fix relic `Area2D.monitoring` physics-lock error.
- [x] Prevent equivalent exit-gate monitoring error on final relic collection.
- [x] Rework melee animation so the whole player no longer rotates.
- [x] Improve jump reach with stronger jump, coyote time and input buffer.
- [x] Normalize platform heights for reachable traversal.
- [x] Fix enemy hurt/death state cleanup.
- [x] Prevent rapid duplicate main-menu actions.
- [x] Freeze enemies behind game-over/win overlays.

## Editing philosophy
Do not hide ordinary level design inside procedural GDScript. Use `.tscn` scenes, child nodes, `AnimatedSprite2D`, `AnimationPlayer`, `AudioStreamPlayer`, `CollisionShape2D`, resources, and exported Inspector variables wherever practical so the project owner can open Godot and change things visually.

## Recovery rule
If a later chat says “continue where you stopped”, first inspect `CURRENT_STATUS.md`, this plan, and `checkpoints/V2_2026-09-10_MANIFEST.txt`. Continue from V2 instead of starting over.

## Next phase
User-side runtime/playtest feedback in Godot 4.7.2. Patch only confirmed issues from this V2 checkpoint and issue a new numbered ZIP.
