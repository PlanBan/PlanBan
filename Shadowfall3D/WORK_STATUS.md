# Shadowfall3D — WORK STATUS

## Current base
- Project line: approved staged Shadowfall3D, Stage 11/20.
- Latest local checkpoint commit: `21ad73c` — `11/20 checkpoint: replace start nature with Quaternius pack`.
- Import checkpoint: `d3f9b15`.
- Previous one-scene checkpoint: `d5d9441`.
- Do not return to the rejected simplified Full Game prototype.

## ONE SCENE START
Open this one scene for start-world editing:
`scenes/main/Stage09QuestGuild.tscn`

The current start remains physically stored in that one scene: road, forest, start houses/interiors, caravan/merchant/corpses/sword, Ravenfall gate and Ravenfall city. Actual New Game route remains `Stage11Rangers -> Stage10OldFarmContract -> Stage09QuestGuild`, so Stage09 edits propagate into the current build.

## 2026-09-08 — Quaternius CC0 nature refresh COMPLETE
User supplied `drive-download-20260908T124025Z-1-001.zip`.

Verified included license:
- LowPoly Models by @Quaternius
- CC0 1.0 Universal / Public Domain Dedication

Implemented:
- Curated 45-model green forest subset imported into `assets/third_party/quaternius_nature/` as OBJ+MTL.
- `License.txt` preserved and source/license recorded in `THIRD_PARTY_ASSETS.md`.
- All 80 placed start-forest temporary tree instances replaced with direct Quaternius pine/birch/common-tree/willow meshes.
- 34 bushes, 26 grass objects, 14 flowers/plants and 10 rocks replaced with Quaternius assets.
- Small Ravenfall city vegetation set also replaced with Quaternius assets.
- Added extra dead trees, stumps and fallen logs around the road/ambush/forest edges.
- No new environment level scene was introduced; every placed nature object remains selectable/editable directly in Stage09.

Optimization:
- 38 far trees are direct MeshInstance3D nodes without physics collision.
- 42 near/playable-area trees keep cheap shared trunk collision.
- Small foliage/rocks use no dynamic shadows/GI and visibility-range culling.
- Imported MTL specular values were reduced for a rougher, less plastic dark-fantasy look.
- Approximate Quaternius geometry if all 178 placed mesh uses were visible at once: ~198,826 triangles; culling reduces actual frame load.

Validation:
- All 45 imported OBJ models parse successfully.
- Every imported OBJ has its MTL sidecar.
- 0 missing ExtResource IDs.
- 0 missing SubResource IDs.
- 0 missing `res://` resource paths.
- 0 duplicate resource IDs in Stage09 static validation.
- JSON validation passes.
- Native Godot executable is not installed in the execution environment, so runtime validation must be performed in the user's Godot 4.7.x.

Recovery:
Resume from local commit `21ad73c` or `Shadowfall3D_quaternius_start_refresh_checkpoint.zip` / newer final ZIP. Do not re-split the start across multiple level scenes.
