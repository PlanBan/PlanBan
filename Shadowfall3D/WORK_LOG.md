# Shadowfall3D — WORK LOG

## 2026-09-08 — one-scene start conversion
- Audited the actual inheritance chain: Stage11 -> Stage10 -> Stage09.
- Confirmed the start was split between Stage09 and RoadsideExpansion.
- Merged RoadsideExpansion content directly into Stage09 and removed the separate Stage10 instance.
- Merged both forest sets under Stage09 `Forest`.
- Flattened cabins, Ravenfall gate and Ravenfall city into Stage09 while preserving gameplay paths.
- Local checkpoint: `d5d9441`.

## 2026-09-08 — runtime launch hotfix
- Fixed malformed Stage09 city patrol PackedVector3Array serialization reported by the user's Godot 4.7.2 runtime screenshot.
- Local hotfix: `bb4daf5`.

## 2026-09-08 — three-pack asset replacement
- Ultimate RPG Items, Ultimate Stylized Nature and LowPoly Nature archives inspected; Quaternius CC0 licenses verified.
- Existing weapon/item visuals replaced in place: swords, bow, arrows, NPC weapons, gold, loot bag/crystal and relevant icons/previews.
- Existing nature replaced in place with Stylized Nature, retaining LowPoly logs/stumps where useful.
- No duplicate environment layer/items added.
- Local checkpoints include `a8d74d0`, `8954681`, `6841d81`.

## 2026-09-08 — Stage 12 magic core checkpoint
- User explicitly asked to continue story/game creation; Stage12 development started.
- Added Player MP/max MP/regeneration/regeneration delay and MP HUD.
- Added magic mode integrated with existing sword/bow modes.
- Added seven schools: Fire, Ice, Lightning, Healing, Protection, Light, Dark.
- Controls: 4–8 select core spells, Q/R cycles all schools, LMB casts while magic mode is active.
- Added physical/ray-stepped magic projectile, lightning hitscan beam, healing, ward, light burst and dark lifesteal.
- Added base elemental resistances and fire/ice/lightning status effects to current enemies.
- Corrupted Wolf inherits the Rift Scavenger resistance system.
- Added BowController safe deactivate hook to prevent overlapping bow/magic visuals.
- Static resource/TSCN/JSON validation and diff check completed.
- Local commit: `b6211e7`.
- Local ZIP: `Shadowfall3D_12_magic_core_checkpoint.zip`.
- GitHub recovery file: `STAGE12_MAGIC_CORE.patch`.

## Next
Build Stage12 story integration: Selen/Arcanists, Arcane Trial region, quest, magic-resistant enemies, Stage12 save/load and Main Menu route.
