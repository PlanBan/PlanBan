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
