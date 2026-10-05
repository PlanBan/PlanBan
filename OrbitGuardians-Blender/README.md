# Astra 3D — оригинальная библиотека Blender

Откройте `AstraLibrary.blend` в Blender 4.3.2. 54 коллекции содержат модели девяти защитников, шести врагов и 30 вариантов для планет, двух кораблей, пяти окружений, ядра и планеты.

45 моделей машин имеют риг из 13 костей. В NLA находятся клипы **Idle, Walk, Attack, Deploy, Death**. Геометрия привязана к костям; GLB использует те же анимации в Godot. После экспорта коллекции перемещены в сетку для удобного осмотра библиотеки.

Полный воспроизводимый генератор — `../OrbitGuardians/tools/generate_models.py`; запуск из папки проекта:

```sh
blender --background --factory-startup --python tools/generate_models.py
```

Генератор создаёт модели с нуля и заменяет библиотеку и экспортированные файлы. Перед собственным редактированием сохраните отдельную копию `.blend`, чтобы повторная генерация её не затёрла. Blender не требуется игрокам и не вызывается игрой.

Модели, риги и клипы созданы специально для этой игры. Сторонние модели и скачанные персонажи не использовались.

## Astra Tabletop / version 4.0

`AstraTabletop.blend` is the new editable source: the complete industrial table,
lamps, conduits, physical decks, tools and 45 card machines/planet variants.
Collections for machines are arranged to the right of the table for inspection.
Every geometry part is original, authored with `tools/generate_tabletop.py`.
The exported game uses 46 merged static GLBs and 45 rendered portraits under
`OrbitGuardians/assets3d/tabletop/`. There is no external game/card artwork.
Cards, miniatures and effects are animated procedurally in Godot; these static
card machines do not claim the skeletal clips found in the older library.

Regenerate from the Godot project directory with Blender 4.3.2:

```sh
blender --background --factory-startup --python tools/generate_tabletop.py
# Export geometry while keeping the previously rendered portraits:
blender --background --factory-startup --python tools/generate_tabletop.py -- --skip-portraits
```

Save edited work under another filename before regeneration. Cycles uses CPU
rendering and does not need OpenImageDenoise. The older `AstraLibrary.blend`
remains available, including the original animated robots and ships.
