# Shadowfall3D — Stage 11/20 live status

## Base
Approved user build: `Shadowfall3D_10_EXPANDED_GUIDANCE(1).zip`.

## Persistence rule
Stage 11 is saved in many small checkpoints. After each logical block: update local WORK_LOG/WORK_STATUS, local Git commit, local ZIP checkpoint, and refresh this GitHub status.

## Current state
Stage 11 is feature-complete, but the first user runtime launch exposed a Godot 4.7.2 parser type-inference error in the new Ravenfall battlement calculation. That runtime parser bug has now been fixed and a new hotfix checkpoint has been created.

Completed Stage 11 content:
- restored Ravenfall south/front fortress wall, battlements and corner towers while preserving the existing gate and city layout;
- Ranger bow, hunting arrows and Ranger quiver as real inventory items with icons;
- physical 3D arrows with gravity/collision and approximate head/body/limb damage multipliers;
- BowController: [2] bow, [3] sword, RMB draw, LMB release, strength/accuracy and ammo HUD;
- ranged enemy AI with NavigationAgent3D, LOS, range management, retreat/search and physical arrow attacks;
- Rangers story: Kael -> training camp -> Lira Thorn -> bow training -> two ranged raiders -> reward;
- Stage 11 quest, guidance, rewards and save/load state;
- Stage 10 city/story/inventory/melee/guidance preserved.

## Parser hotfix
User screenshot showed:
`ravenfall_city_builder.gd:50 — Cannot infer the type of "x" variable because the value doesn't have a set type.`

Fix:
- replaced the risky inferred `var x := ...` calculation with explicit float typing/conversion;
- typed the Stage 11 ranger-region Vector3 array;
- proactively removed runtime `:=` inference from newly added bow, arrow projectile and ranged-raider locals where practical, so the next Stage 11 line is less likely to trigger the same Godot parser behavior.

## Validation after hotfix
- 0 missing `res://` resources;
- 0 unresolved TSCN ExtResource/SubResource IDs;
- JSON files parse successfully;
- `git diff --check` clean;
- exact reported `var x :=` pattern is gone;
- no runtime `:=` remains in the newly added bow/arrow/ranged Stage 11 scripts (constants excluded).

Native Godot is not installed in the build environment, so user runtime launch is still the final verification.

## Recovery state
Latest local Git HEAD: `fe7fb3e` (`stage11: fix Godot 4.7 parser type inference`).
Latest local ZIP checkpoint: `09_stage11_parser_hotfix.zip`.
Previous checkpoints 00–08 remain available locally.

## Next action
Deliver `Shadowfall3D_11_of_20_PARSER_FIXED.zip` and wait for user confirmation. Do not start Stage 12 until Stage 11 opens cleanly in the user's Godot 4.7.2.
