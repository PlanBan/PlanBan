# Shadowfall3D — WORK LOG

## 2026-09-08 — one-scene start conversion
- Audited the actual inheritance chain: Stage11 -> Stage10 -> Stage09.
- Confirmed the start was split between Stage09 and RoadsideExpansion.
- Merged RoadsideExpansion content directly into Stage09 and removed the separate Stage10 instance.
- Merged both forest sets under Stage09 `Forest`.
- Flattened the three start cabin scenes into Stage09, preserving their furniture/interiors.
- Flattened Ravenfall gate into Stage09 while preserving gameplay paths.
- Flattened Ravenfall city into Stage09 while preserving city trigger paths and NPC groups.
- Static validation completed.
- Local checkpoint: `d5d9441`.

## 2026-09-08 — runtime launch hotfix
- Fixed malformed Stage09 city patrol PackedVector3Array serialization reported by the user's Godot 4.7.2 runtime screenshot.
- Local hotfix: `bb4daf5`.

## 2026-09-08 — RPG Items replacement pass
- Inspected user-provided Ultimate RPG Items archive and verified Quaternius CC0 1.0 license.
- Imported curated replacement subset.
- Replaced old_sword, iron_sword, bow, physical arrows, world pickup and inventory previews with RPG-pack meshes.
- Replaced Ranged Raider bow, Gate Sentry weapon and Captain Garrett weapon.
- Replaced existing GoldPickup with RPG coins and LootPile visual with Bag + Crystal.
- Replaced weapon icons and removed unused old SVG weapon icons.
- Potions intentionally preserved.
- Local checkpoints: `6d8ef95`, `a8d74d0`.

## 2026-09-08 — Ultimate Stylized Nature replacement
- Imported curated Stylized Nature subset with CC0 license.
- Remapped 41 existing Stage09 nature resource IDs in place to stylized equivalents rather than adding a duplicate environment layer.
- Applied per-resource scale compensation from old/new OBJ bounds so existing layout size is preserved.
- Rewrote reusable PineTree/PineTreeTall/PineTreeWide/BirchTree/BushClump/GrassClump/FlowerPatch/RockCluster scenes to use stylized Quaternius mesh assets instead of primitive procedural meshes.
- Stage10 Old Farm and Stage11 Ranger Camp therefore inherit the new nature style automatically through their existing scene references.
- Logs/stumps remain from the supplied LowPoly Nature archive where Stylized Nature has no corresponding model.
- Static validation: 0 missing res paths, 0 unresolved resource IDs, JSON valid, diff check clean.
- Local checkpoints: `3a89886`, `8954681` / `Shadowfall3D_stylized_nature_replacement_checkpoint.zip`.

## 2026-09-08 — weapon cleanup follow-up
- Replaced CombatEffigy primitive practice BladeMesh/GuardMesh with RPG-pack Sword mesh.
- Removed obsolete primitive practice-weapon subresources.
- Local checkpoint: `6841d81`.
