# Shadowfall3D — WORK STATUS

## Current base
- Project line: approved staged Shadowfall3D, Stage 11/20.
- Latest local checkpoint commit: `d3f9b15` — `11/20 checkpoint: import Quaternius CC0 nature pack subset`.
- Previous one-scene checkpoint: `d5d9441`.
- Do not return to the rejected simplified Full Game prototype.

## COMPLETE START IN ONE TSCN
Open this one scene for start-world editing:
`scenes/main/Stage09QuestGuild.tscn`

The current start remains physically stored in that one scene: road, forest, start houses/interiors, caravan/merchant/corpses/sword, Ravenfall gate and Ravenfall city. Actual New Game route remains `Stage11Rangers -> Stage10OldFarmContract -> Stage09QuestGuild`, so Stage09 edits propagate into the current build.

## 2026-09-08 — Quaternius nature refresh in progress
User supplied `drive-download-20260908T124025Z-1-001.zip`.

Verified pack metadata from its included license:
- LowPoly Models by @Quaternius
- License: CC0 1.0 Universal / Public Domain Dedication

Completed checkpoint:
- Imported curated green forest subset into `assets/third_party/quaternius_nature/`.
- Preserved `License.txt`.
- Added source/license entry to `THIRD_PARTY_ASSETS.md`.
- Imported pine, birch, common-tree, willow, dead-tree, bush, grass/plant/flower, rock/moss-rock, stump and log OBJ+MTL assets.
- Snow, palm and cactus variants were intentionally not imported to keep the active project smaller.
- Local ZIP checkpoint: `Shadowfall3D_quaternius_import_checkpoint.zip`.

### Exact next step
Mass-replace the temporary placed nature in `scenes/main/Stage09QuestGuild.tscn` while preserving the ONE-SCENE requirement:
1. Replace `Forest` temporary tree PackedScene instances with direct Quaternius OBJ-backed MeshInstance3D tree nodes, retaining positions/rotation variety and simple near-road collisions.
2. Replace `EDIT_ME_START_BushesGrassRocks` temporary bushes/grass/flowers/rocks with Quaternius models.
3. Add a small number of Quaternius stumps/logs/dead trees around the ambush and forest edges.
4. Apply visibility-range/shadow optimization and run static TSCN/resource validation.

## Recovery
Resume from local commit `d3f9b15` or `Shadowfall3D_quaternius_import_checkpoint.zip`. Do not re-split the start across multiple level scenes.
