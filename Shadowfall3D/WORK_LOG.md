# Shadowfall3D — WORK LOG

## 2026-09-08 — one-scene start conversion
- Audited the actual inheritance chain: Stage11 -> Stage10 -> Stage09.
- Confirmed the start was split between Stage09 and RoadsideExpansion.
- Merged RoadsideExpansion content directly into Stage09 and removed the separate Stage10 instance.
- Merged both forest sets under Stage09 `Forest`.
- Flattened the three start cabin scenes into Stage09, preserving their furniture/interiors.
- Flattened Ravenfall gate into Stage09 while preserving script paths such as `Ravenfall/GateLeft`, `Ravenfall/GateSentry`, and `Ravenfall/CaptainGarrett`.
- Flattened Ravenfall city into Stage09 while preserving city trigger paths and NPC groups.
- Imported all needed ExtResource/SubResource declarations with collision-safe IDs.
- Final static validation: 0 missing resources, 0 unresolved resource IDs, 0 duplicate TSCN resource IDs.
- Local checkpoint commit: `d5d9441`.
- Recovery checkpoint: `Shadowfall3D_ONE_SCENE_START_FINAL_checkpoint.zip`.

## 2026-09-08 — Quaternius nature-pack refresh
- Verified user-provided nature pack license: LowPoly Models by @Quaternius, CC0 1.0 Universal / Public Domain Dedication.
- Imported a curated 45-model green-forest subset into `assets/third_party/quaternius_nature/` instead of the full 150-model pack.
- Preserved `License.txt` and documented the source/license in `THIRD_PARTY_ASSETS.md`.
- Replaced all 80 placed start-forest temporary tree instances in Stage09 with direct Quaternius OBJ-backed nodes using pine/birch/common-tree/willow variety.
- Replaced 34 bushes, 26 grass clumps, 14 flower/plant spots and 10 rock spots with Quaternius assets.
- Replaced the small Ravenfall city vegetation set with Quaternius assets too.
- Added hand-placed Quaternius dead trees, stumps and fallen logs around the road/ambush/forest edges.
- Kept the one-scene rule: all placed nature remains directly selectable in `Stage09QuestGuild.tscn`; no new environment level scenes were introduced.
- Optimization: 38 far trees are direct MeshInstance3D nodes without physics; 42 near/playable-area trees retain cheap shared trunk collision; small foliage has shadows/GI disabled and visibility-range culling.
- Tuned imported MTL specular values to reduce the plastic look under dark-fantasy lighting.
- All 45 imported OBJ files parse successfully and have MTL sidecars.
- Approximate Quaternius geometry if every placed imported mesh were visible simultaneously: ~198,826 triangles before culling.
- Static validation passes: no missing ExtResource/SubResource IDs, no missing `res://` paths, no duplicate resource IDs, all JSON parses.
- Local import checkpoint: `d3f9b15` / `Shadowfall3D_quaternius_import_checkpoint.zip`.
- Local replacement checkpoint: `21ad73c` / `Shadowfall3D_quaternius_start_refresh_checkpoint.zip`.
