# Stage 3 — Universal Battle Framework

Completed: 2026-09-11
Target: Godot 4.7.2 stable

This stage creates the reusable battle foundation for WURZELHERZ.

## Editor-editable structure
- `scenes/battle/BattleScene.tscn`: regular Control/Panel/Button/ProgressBar/Node2D scene.
- `scenes/battle/components/BattleSoul.tscn`: separate red-heart Area2D scene.
- `scenes/battle/components/BattleProjectile.tscn`: reusable projectile scene.
- `scenes/battle/enemies/TestEnemyVisual.tscn`: enemy visual made from normal editable Godot nodes.
- `scenes/battle/data/TestEnemy.tres`: enemy stats, German dialogue, ACT choices and pattern settings in a Resource.
- `scenes/world/components/BattleTrigger.tscn`: reusable world interaction that starts a battle.

## Framework behavior
- Commands: KÄMPFEN / HANDELN / ITEM / VERSCHONEN.
- Timed strike meter for KÄMPFEN.
- ACT actions can raise mercy progress.
- VERSCHONEN becomes available after enemy-specific conditions.
- Red-heart dodge arena with clamped movement and hit invulnerability.
- Generic projectile spawning supports `rain`, `sides`, and `aimed` patterns.
- Enemy data uses `BattleEnemyData`, so chapter bosses can reuse BattleScene instead of duplicating battle code.
- Win/mercy choices update GameState route counters and story flags.
- Defeat has retry/main-menu flow.

## Test encounter
`RootHall.tscn` contains `TrainingEncounter`, using `TestEnemy.tres` (WURZEL-NOVIZE). After the encounter it returns to `AfterTestBattle` in the same room and will not start again once its completion flag is set.

## Validation
Static validator: PASS, zero errors for current project references, TSCN/TRES load_steps, connection method presence, required inputs, duplicate GDScript functions and Stage 3 structure.

Runtime note: no runnable Godot 4.7.2 binary is available in the build environment, so engine-boot playtesting is not claimed.
