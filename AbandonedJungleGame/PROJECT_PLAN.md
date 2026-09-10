# PROJECT PLAN — Abandoned Jungle Game

Target engine: Godot 4.7.2

## Goal
Turn the existing prototype into an editable 2D abandoned-jungle platformer using Godot scenes/resources and free licensed assets.

## Milestones
- [x] Preserve the last working Neon Courier prototype as a recovery checkpoint.
- [x] Document current status and continuation rules.
- [x] Create editable Godot folder structure under `game/`.
- [ ] Create `MainMenu.tscn` with `Play` and `Quit` buttons.
- [ ] Add animated/moving jungle background to the menu.
- [ ] Add player scene with `AnimatedSprite2D` and inspector-editable gameplay values.
- [ ] Add player idle/walk/jump/attack/hurt/death animations.
- [ ] Add enemy scene(s) using free sprite assets and animations.
- [ ] Build first abandoned-jungle/ruins level with editable scene nodes / TileMapLayer.
- [ ] Add collectible/objective and level exit.
- [ ] Add sound effects for UI, footsteps/jump/attack/hurt/collect/exit.
- [ ] Add looping jungle ambience / music from a suitable free-license source.
- [ ] Create `ASSET_LICENSES.md` with source, author, license and attribution details.
- [ ] Validate compatibility with Godot 4.7.2.
- [ ] Build a ready-to-import ZIP checkpoint.
- [ ] Update `CURRENT_STATUS.md` after every substantial milestone.

## Editing philosophy
Do not hide ordinary level design inside procedural GDScript. Use `.tscn` scenes, child nodes, `AnimatedSprite2D`, `AnimationPlayer`, `AudioStreamPlayer`, `CollisionShape2D`, `TileMapLayer`, resources, and exported Inspector variables wherever practical so the project owner can open Godot and change things visually.

## Recovery rule
If a later chat says “continue where you stopped”, first inspect this file and `CURRENT_STATUS.md`, then continue from the first unchecked item instead of starting over.
