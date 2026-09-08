# Shadowfall3D — WORK STATUS

## Current base
- Project line: approved staged Shadowfall3D, Stage 11/20.
- Current local source checkpoint commit: `fbc3cee`.
- Previous checkpoints: `d2a0a33`, `e5a88e1`, `71ab4cd`.
- Do not return to the rejected simplified Full Game prototype.

## 2026-09-08 — EDITABLE WORLD conversion
The current Stage 11 world art was restructured so the user can manually edit it in Godot 3D instead of relying on runtime-only environment builders.

Editable scenes:
- `scenes/world/RoadsideExpansion.tscn` — start road, houses, forest, bushes, grass, flowers and rocks.
- `scenes/world/RavenfallGateEditable.tscn` — Ravenfall gate, towers and decoration.
- `scenes/world/RavenfallCityEditable.tscn` — city walls, streets, buildings, props, NPCs and triggers.
- `scenes/world/OldFarmRegion.tscn` — Old Farm visuals and gameplay wolves.
- `scenes/world/RangerTrainingRegion.tscn` — Ranger camp and forest edge.
- `scenes/world/EDIT_WORLD_OVERVIEW.tscn` — daylight overview for manual level-art work.
- `scenes/main/Stage09QuestGuild.tscn` — base gameplay start inherited by Stage10/Stage11: player, wounded merchant, caravan, near-road forest and scene gameplay nodes.
- Actual New Game scene remains `scenes/main/Stage11Rangers.tscn`.

Important implementation state:
- Roadside visuals are no longer created by `roadside_expansion.gd`; the scene contains real editor-visible nodes.
- Ravenfall city is now instanced from `RavenfallCityEditable.tscn` instead of the runtime city builder.
- Old Farm and Ranger camp environment objects are stored in their TSCN files; scripts are reduced to gameplay/navigation accessors where needed.
- Ravenfall gate was extracted to `RavenfallGateEditable.tscn`; stage_06 uses direct `Ravenfall/...` node paths.
- Stage09 close forest now mixes pine/tall pine/wide pine/birch variants.
- A generated cobblestone road texture is used as one central road surface instead of hundreds of separate stone meshes.
- Optimization: small foliage/flowers/rocks have shadows disabled and visibility-range culling; trees have distance culling while keeping shadows.
- `EDIT_ME_FIRST.md` and `docs/EDITING_WORLD.md` explain manual editing.

Validation at checkpoint:
- Static TSCN resource validation: 0 missing `res://` resources.
- 0 unresolved ExtResource/SubResource IDs.
- JSON validation passes.
- Native Godot runtime validation is still required on the user's Godot 4.7.2 installation.

## Recovery rule
On resume: read `MAIN_NOTE.md`, then this file, then `WORK_LOG.md`. Continue from the latest editable-world checkpoint rather than rebuilding the environment from scripts.
