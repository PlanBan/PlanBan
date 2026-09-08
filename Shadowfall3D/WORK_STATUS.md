# Shadowfall3D — WORK STATUS

## Current base
- Project line: approved staged Shadowfall3D, Stage 11/20.
- Latest local checkpoint commit: `ec33495` — `Checkpoint: unify complete start into Stage09 scene`.
- Previous editable-world checkpoint: `fbc3cee`.
- Do not return to the rejected simplified Full Game prototype.

## 2026-09-08 — ONE SCENE START WORLD
The user correctly reported that the start was still scattered between `Stage09QuestGuild.tscn` and a separately instanced `RoadsideExpansion.tscn`.

This has now been structurally fixed:
- `RoadsideExpansion.tscn` content is merged directly into `scenes/main/Stage09QuestGuild.tscn`.
- `Stage10OldFarmContract.tscn` no longer instances RoadsideExpansion separately.
- Original Stage09 trees and former RoadsideExpansion trees are combined under the single `Forest` node: 80 editor-visible tree instances at this checkpoint.
- Start houses are in `EDIT_ME_START_Houses`.
- Cobble road / expanded ground / house paths are in `EDIT_ME_START_RoadAndGround`.
- Bushes, grass, flowers and rocks are in `EDIT_ME_START_BushesGrassRocks`.
- `BrokenCaravan`, `WoundedMerchant`, corpses, sword pickup, encounter and enemies remain in the same Stage09 scene.
- `Ravenfall` gate and `RavenfallCity` are present directly in Stage09 and have Editable Children enabled, so they can be manipulated while editing Stage09 without opening another level scene.
- Cabin instances also have Editable Children enabled for furniture/interior edits.

### Single scene to edit the current start
`scenes/main/Stage09QuestGuild.tscn`

Actual New Game remains:
`Stage11Rangers.tscn -> Stage10OldFarmContract.tscn -> Stage09QuestGuild.tscn`
Therefore edits saved in Stage09 propagate into the current Stage11 New Game build.

## Validation
- 0 missing `res://` resources.
- 0 unresolved TSCN ExtResource/SubResource IDs.
- 0 duplicate resource IDs in TSCN validation.
- JSON validation passes.
- Stage10 contains no RoadsideExpansion instance after merge.
- Native Godot executable is not installed in the current execution environment, so runtime validation must be performed in the user's Godot 4.7.x.

## Recovery rule
On resume: read `MAIN_NOTE.md`, then this file, then `WORK_LOG.md` if present. Continue from local checkpoint `ec33495` / `Shadowfall3D_one_scene_start_checkpoint.zip` or newer. Do not re-split the start into separate runtime environment scenes.
