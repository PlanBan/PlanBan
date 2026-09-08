# Shadowfall3D — WORK STATUS

## Current base
- Project line: approved staged Shadowfall3D, Stage 11/20.
- Latest local checkpoint commit: `d5d9441` — `Checkpoint: flatten full start into one Stage09 TSCN`.
- Previous merge checkpoint: `ec33495`.
- Do not return to the rejected simplified Full Game prototype.

## 2026-09-08 — COMPLETE START IN ONE TSCN
The user's requirement is now implemented literally: the current start-world layout is stored in one level scene.

### Open this one scene for start-world editing
`scenes/main/Stage09QuestGuild.tscn`

It directly contains:
- start road and cobblestone center strip;
- all placed start-forest trees (80 direct instances under `Forest` at checkpoint);
- bushes, grass, flowers and rocks;
- all three start houses and their interior/furniture nodes;
- broken caravan, wounded merchant, road corpses, old sword pickup;
- start encounter trigger and enemies;
- Ravenfall gate geometry, towers and gate NPCs;
- full Ravenfall city geometry, buildings, streets, market props, vegetation, NPCs and city triggers.

The former level scenes are no longer referenced by Stage09:
- `RoadsideExpansion.tscn`
- `RavenfallGateEditable.tscn`
- `RavenfallCityEditable.tscn`
- `ForestRangerCabin.tscn`
- `AbandonedCabin.tscn`
- `HunterCabin.tscn`
They remain only as backup/source assets.

Reusable object assets such as Player, individual tree models, NPC character scenes and enemy scenes remain PackedScene instances, but every placed instance is visible/selectable from the single Stage09 Scene Tree.

Actual New Game route remains:
`Stage11Rangers.tscn -> Stage10OldFarmContract.tscn -> Stage09QuestGuild.tscn`
So edits to Stage09 automatically propagate into the current Stage11 build.

## Validation
- Stage09 contains 1163 scene nodes at the flatten checkpoint.
- 0 missing `res://` resources.
- 0 unresolved TSCN ExtResource/SubResource IDs.
- 0 duplicate TSCN resource IDs in static validation.
- Stage10 no longer instances RoadsideExpansion.
- Native Godot executable is unavailable in the execution environment, so runtime validation is still required in the user's Godot 4.7.x.

## Recovery
Resume from local commit `d5d9441` or `Shadowfall3D_ONE_SCENE_START_FINAL_checkpoint.zip` / newer final ZIP. Do not re-split the start across multiple level scenes.
