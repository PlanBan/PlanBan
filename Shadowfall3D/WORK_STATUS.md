# Shadowfall3D — WORK STATUS

## Current base
- Project line: approved staged Shadowfall3D, Stage 11/20.
- Latest local checkpoint commit: `bb4daf5` — `11/20 hotfix: fix Stage09 PackedVector3Array parser error`.
- Quaternius replacement checkpoint: `21ad73c`.
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

## 2026-09-08 — Godot 4.7.2 runtime parser hotfix
User runtime screenshot showed New Game could not launch and the editor reported a parse error in `Stage09QuestGuild.tscn` around line 5800. Because Stage10 and Stage11 inherit Stage09, that one base-scene parse failure cascaded into many additional errors.

Root cause fixed:
- `CityPatrol.patrol_points` had been serialized as invalid `PackedVector3Array(Vector3(...), ...)` text during city flattening.
- `SquareGuard.patrol_points` had the same invalid form.
- `Citizen.patrol_points` had the same invalid form.
- All three are now serialized in canonical Godot TSCN packed-vector form using flat numeric values, e.g. `PackedVector3Array(0, 0, 0, ...)`.
- The same malformed values were corrected in backup `scenes/world/RavenfallCityEditable.tscn` so the bug is not reintroduced from that source scene.
- Project-wide search finds 0 remaining `PackedVector3Array(Vector3...)` TSCN expressions.

Validation after hotfix:
- all referenced `res://` resources exist;
- TSCN ExtResource/SubResource references resolve statically;
- JSON validation passes;
- packed-vector serialization now matches canonical Godot `.tscn` examples;
- current local checkpoint ZIP: `Shadowfall3D_runtime_parser_hotfix_checkpoint.zip`.

Native Godot 4.7.2 is not installed in the execution container, so final runtime confirmation must still be done in the user's Godot 4.7.2 editor.

## Recovery
Resume from local commit `bb4daf5` or `Shadowfall3D_runtime_parser_hotfix_checkpoint.zip` / newer final ZIP. Do not re-split the start across multiple level scenes and do not restore the malformed PackedVector3Array syntax.