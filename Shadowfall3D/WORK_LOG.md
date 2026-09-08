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
- Imported a curated green-forest subset into `assets/third_party/quaternius_nature/`.
- Replaced the active start forest/bush/grass/flower/rock placeholders while preserving the one-scene Stage09 layout.
- Optimization/culling pass and static validation completed.
- Local replacement checkpoint: `21ad73c`.

## 2026-09-08 — runtime launch hotfix
- Investigated user screenshot showing 44 editor errors and New Game failing.
- Traced the first real error to `Stage09QuestGuild.tscn` line ~5800.
- Rewrote three malformed patrol routes to canonical Godot PackedVector3Array syntax.
- Local hotfix commit: `bb4daf5`.

## 2026-09-08 — RPG Items replacement pass
- Inspected the user-provided Ultimate RPG Items archive and verified Quaternius CC0 1.0 license.
- Imported a curated replacement subset into `assets/third_party/quaternius_rpg_items/` with its license.
- Replaced existing `old_sword` with `Sword.obj` and `iron_sword` with `Sword_big.obj`; did not leave the old procedural weapon meshes beside them.
- Replaced ranger/player bow with `Bow_Wooden.obj`, keeping the gameplay-controlled draw/string logic.
- Replaced physical arrow visual with `Arrow.obj` while preserving projectile gravity/collision/hit multipliers.
- Added distinct first-person switching between old_sword and iron_sword by existing item ID, without changing item stats.
- Replaced world pickup and inventory previews for swords/bow/armor with pack meshes.
- Replaced Ranged Raider bow, Gate Sentry weapon and Captain Garrett weapon so active start NPCs no longer retain the old primitive weapon design.
- Replaced existing GoldPickup cylinder visuals with RPG-pack Coin meshes.
- Replaced existing LootPile primitive sack/crystal visuals with RPG-pack Bag and Crystal meshes; loot logic unchanged.
- Replaced existing weapon icons with matching RPG-pack PNGs and removed now-unused old internal weapon SVGs.
- Potions were intentionally left alone except for no-op preservation, per user request.
- Validation: 0 missing res paths, Ext/Sub resources resolve, JSON passes, packed arrays remain canonical, RPG OBJ/MTL sidecars present, `git diff --check` clean.
- Local import checkpoint: `6d8ef95`.
- Local weapon replacement checkpoint: `a8d74d0` / `Shadowfall3D_rpg_weapon_replacement_checkpoint.zip`.
- Next: replace existing nature/decor in-place using Ultimate Stylized Nature + the supplied LowPoly Nature archive, without increasing object count or breaking the one-scene start.