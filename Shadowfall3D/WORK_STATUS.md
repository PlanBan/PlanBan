# Shadowfall3D — WORK STATUS

## Current base
- Project line: approved staged Shadowfall3D, Stage 11/20.
- Latest local checkpoint commit: `a8d74d0` — `11/20 checkpoint: replace existing weapon visuals with RPG pack`.
- RPG import checkpoint: `6d8ef95`.
- Runtime parser hotfix: `bb4daf5`.
- Quaternius nature replacement checkpoint: `21ad73c`.
- Do not return to the rejected simplified Full Game prototype.

## ONE SCENE START
Open this one scene for start-world editing:
`scenes/main/Stage09QuestGuild.tscn`

The current start remains physically stored in that one scene: road, forest, start houses/interiors, caravan/merchant/corpses/sword, Ravenfall gate and Ravenfall city. Actual New Game route remains `Stage11Rangers -> Stage10OldFarmContract -> Stage09QuestGuild`, so Stage09 edits propagate into the current build.

## 2026-09-08 — RPG ITEMS WEAPON/DESIGN REPLACEMENT CHECKPOINT
User supplied `Ultimate RPG Items Pack - Aug 2019-20260908T130721Z-1-001.zip` and explicitly requested replacement rather than additive duplicates.

Verified included license:
- LowPoly Models by @Quaternius
- CC0 1.0 Universal / Public Domain Dedication

Completed replacement block:
- `old_sword` visual replaced with Quaternius `Sword.obj`.
- `iron_sword` visual replaced with distinct Quaternius `Sword_big.obj`.
- `ranger_bow` visual replaced with `Bow_Wooden.obj`; existing draw mechanic retained with a dynamic game-controlled string.
- `hunting_arrow` / physical projectile visual replaced with `Arrow.obj` while gravity/collision/damage logic remains unchanged.
- Player first-person weapon switching now shows the correct old/iron sword model by item ID without changing gameplay stats.
- World sword pickup and inventory 3D previews now use the same replacement assets.
- Ranged raider bow, Gate Sentry weapon and Captain Garrett weapon were replaced so old primitive weapon geometry does not remain in the active start.
- Existing armor previews use RPG-pack leather/metal armor meshes.
- Existing gold pickup visual replaced with RPG-pack coins.
- Existing LootPile sack/crystal visual replaced with RPG-pack Bag + Crystal; loot behavior unchanged.
- Existing weapon item icons replaced with matching pack PNG icons.
- Old internal SVG weapon icons were removed after confirming there were no remaining references.
- Potions were intentionally not mass-redesigned.

Preserved logic:
- item IDs, melee/ranged stats, stamina costs, bow ammo logic, arrow flight/hit logic and quest/inventory behavior were preserved.

Validation at this checkpoint:
- 0 missing `res://` resources.
- TSCN ExtResource/SubResource references resolve statically.
- 0 duplicate TSCN resource IDs.
- JSON validation passes.
- 0 malformed `PackedVector3Array(Vector3...)` expressions.
- imported RPG OBJ files have MTL sidecars.
- `git diff --check` was clean before commit.
- Native Godot runtime is still not available in the execution container; user runtime test remains required.

Local recovery ZIP:
`Shadowfall3D_rpg_weapon_replacement_checkpoint.zip`

## Exact next step
Continue the same user request using the other two supplied nature archives, still by REPLACEMENT rather than adding duplicates:
1. Import a curated subset from `Ultimate Stylized Nature - May 2022-20260908T131010Z-1-001.zip` with its CC0 license.
2. Replace existing live Stage09 tree/bush/grass/flower/rock mesh resources in-place while preserving object count/positions and the one-scene rule.
3. Use the third LowPoly Nature archive only for appropriate complementary replacements where the stylized pack has no good equivalent (willow/log/stump/dead accents etc.).
4. Replace existing matching decor props from the RPG pack only where a current old placeholder exists; do not add loot/rewards/items just to show more assets.
5. Re-run full static validation, save checkpoints, then package final ZIP.

## Recovery
Resume from local commit `a8d74d0` or `Shadowfall3D_rpg_weapon_replacement_checkpoint.zip`. Preserve the one-scene start and the fixed canonical PackedVector3Array syntax.