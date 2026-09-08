# НАЧАЛО ИГРЫ ТЕПЕРЬ В ОДНОЙ СЦЕНЕ

Открывай для ручного редактирования мира:
`scenes/main/Stage09QuestGuild.tscn`

В этой одной сцене находятся стартовая дорога, весь стартовый лес, кусты/трава/цветы/камни, три дома с мебелью, караван, торговец, старый меч, стартовая засада, ворота Ravenfall и весь город Ravenfall.

Главные папки:
- `Forest` — все деревья начала.
- `EDIT_ME_START_RoadAndGround` — земля, плиточная дорога и тропы.
- `EDIT_ME_START_Houses` — дома и мебель.
- `EDIT_ME_START_BushesGrassRocks` — кусты, трава, цветы и камни.
- `Ravenfall` — ворота и стража.
- `RavenfallCity` — город.

Актуальный New Game запускается через Stage11, но Stage11 наследует Stage10 -> Stage09, поэтому изменения Stage09 автоматически попадают в игру.

Не удаляй без причины Player, триггеры, DialogueSystem, NavigationRegion, ScavengerA/B/C, InventorySystem, QuestSystem, GuildContractBoard и сюжетных NPC.
