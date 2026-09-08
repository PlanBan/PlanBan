# Shadowfall3D — WORK STATUS

## Current base
- Project line: approved staged Shadowfall3D, Stage 11/20.
- Latest local checkpoint commit: `6841d81` — `11/20 checkpoint: replace training blade asset`.
- Stylized Nature replacement checkpoint: `8954681`.
- Stylized Nature import checkpoint: `3a89886`.
- RPG weapon replacement checkpoint: `a8d74d0`.
- RPG import checkpoint: `6d8ef95`.
- Runtime parser hotfix: `bb4daf5`.
- Do not return to the rejected simplified Full Game prototype.

## ONE SCENE START
Open this scene for current start-world editing:
`scenes/main/Stage09QuestGuild.tscn`

Actual New Game route remains:
`Stage11Rangers -> Stage10OldFarmContract -> Stage09QuestGuild`.

## 2026-09-08 — three-pack replacement pass
User requested replacement, not additive duplicates, using three supplied Quaternius archives.

### RPG Items replacement COMPLETE
- old_sword -> Quaternius `Sword.obj`.
- iron_sword -> `Sword_big.obj`.
- ranger_bow/player bow -> `Bow_Wooden.obj`.
- hunting_arrow / physical projectile -> `Arrow.obj`.
- World sword pickup, first-person weapons and inventory previews updated to the same replacement assets.
- Ranged Raider bow, Gate Sentry weapon, Captain Garrett weapon and CombatEffigy practice weapon replaced so primitive weapon geometry does not remain in current gameplay scenes.
- Existing GoldPickup visuals -> RPG `Coin` meshes.
- Existing LootPile visuals -> RPG `Bag + Crystal` meshes.
- Existing armor previews/NPC armor use RPG leather/metal armor meshes.
- Weapon icons replaced by pack PNGs; old unused internal weapon SVGs removed.
- Potions intentionally not mass-redesigned.
- Gameplay IDs, stats, stamina, ammo, projectile, quest and inventory behavior preserved.

### Stylized Nature replacement COMPLETE for active nature pipeline
- Curated Ultimate Stylized Nature subset imported with CC0 license.
- Existing Stage09 living nature resources remapped IN PLACE to Stylized Nature; no second forest/object layer was added.
- Positions/rotations preserved.
- Scale compensation calculated from source/target OBJ bounds to keep world composition close to the previous layout.
- Reusable scenes `PineTree`, `PineTreeTall`, `PineTreeWide`, `BirchTree`, `BushClump`, `GrassClump`, `FlowerPatch`, `RockCluster` were rewritten to use Stylized Nature meshes instead of primitive procedural geometry.
- This automatically updates Stage10 Old Farm, Stage11 Ranger Camp, older stage scenes and backup environment scenes that instance those reusable assets.
- Logs/stumps remain from the supplied LowPoly Nature archive because the Stylized archive has no equivalent.
- Small foliage keeps shadows/GI disabled and visibility culling; trees keep simple collision where reusable wrappers are used.

## Validation
- 0 missing `res://` resources.
- 0 unresolved TSCN ExtResource/SubResource IDs.
- 0 duplicate TSCN resource IDs in static validation.
- JSON validation passes.
- 0 malformed `PackedVector3Array(Vector3...)` expressions.
- `git diff --check` clean at each checkpoint.
- Native Godot 4.7.2 binary could not be downloaded in the execution container because the container has no external network/DNS access. Runtime launch validation still requires Godot on the user's machine unless a runnable Godot binary becomes available here.

## Recovery
Resume from local commit `6841d81` or `8954681` plus newer work. Checkpoints include `Shadowfall3D_stylized_nature_replacement_checkpoint.zip`. Preserve the one-scene start and do not re-add old asset geometry beside replacement assets.
