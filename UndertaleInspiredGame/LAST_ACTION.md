# LAST ACTION

Date: 2026-09-11

Последнее завершённое действие: Stage 2 полностью создан, проверен и сохранён в `UndertaleInspiredGame/game/`. Есть настоящий top-down Player, камера, столкновения, взаимодействия, DialogueBox, две связанные комнаты `MossEntrance` и `RootHall`, немецкие реплики и возврат через корректные spawn points. Stage 2 manifest записан, ROADMAP и CURRENT_STATUS обновлены.

## Что делать следующим
Следующий этап — Stage 3: универсальная BattleScene. Не начинать Moosritter как отдельную уникальную сцену до готовности общего боевого каркаса.

Нужно создать:
1. `scenes/battle/BattleScene.tscn` как переиспользуемую сцену;
2. меню команд `KÄMPFEN / HANDELN / ITEM / VERSCHONEN`;
3. немецкое окно battle dialogue;
4. красное сердце внутри dodge-box с ограниченным движением;
5. player HP и enemy HP;
6. тайминг-метр атаки KÄMPFEN;
7. базовый интерфейс/данные врага, чтобы разные боссы меняли тексты, HP, ACT и паттерны без копирования всей BattleScene;
8. тестовый encounter из RootHall с возвратом обратно после победы/пощады;
9. минимум один безопасный bullet-pattern для проверки dodge phase.

После Stage 3 обязательно: статическая проверка, реальные файлы в GitHub, manifest/checkpoint, обновление CURRENT_STATUS/ROADMAP/LAST_ACTION. Только затем переходить к Chapter 1 / Moosritter.
