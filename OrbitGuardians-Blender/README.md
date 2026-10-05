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

## Astra Diorama / version 4.1

`AstraDioramas.blend` contains five miniature worlds: Verdia's forest and
waterfalls, Borea's glaciers, Ignis's lava, Aurica's desert ruins and Nexus's
machinery. It also contains the worn command desk, route token, Archon gate and
an original articulated explorer. The explorer has Idle, Walk, Attack, Deploy
and Death NLA clips. Its hands are bound to the arm joints, including the lower
knuckles; 572 hand vertices were checked after export preparation.

Ground albedo and normal maps, paths, metal grain and scratches are generated
and packed in the library. All geometry is editable. Static exports are batched
by material; Godot instances the route tokens and dotted links with MultiMesh.
The original explorer also appears on the Pulse card and its battlefield plate.

Regenerate from `OrbitGuardians/`:

```sh
blender --background --factory-startup --python tools/generate_dioramas.py
python3 tools/generate_route_icons.py
blender --background --factory-startup --python tools/render_explorer.py
```

This writes nine GLBs, the route-coordinate manifest, ten original SVG engravings
and the updated explorer portrait. Run the portrait step after re-generating the
older tabletop assets so that Pulse keeps the new explorer. The reference was
used for composition and atmosphere; its image, models and artwork were not
copied into the game. Preserve manual edits under a separate filename before
regeneration.

## Astra Forge / version 4.4

`AstraForge.blend` is a new library built from original geometry: nine friendly
machine archetypes and seven opponents. Biped shooters, multi-legged generators,
hexagonal shields, twin turrets, missile pods and hovering repair machines have
different silhouettes and graphite/ceramic/role-colour materials. Each of the
sixteen exports includes a Skeleton3D-compatible rigid skin and five NLA clips:
**Idle, Deploy, Attack, Hit, Death**. Sixteen Cycles-rendered transparent portraits
are included. Named parts remain individually editable; exports merge by material.

From `OrbitGuardians/`:

```sh
blender --background --factory-startup --python tools/generate_forge.py
```

The generator uses CPU Cycles, 64 samples and no OpenImageDenoise dependency.
It writes its own new library/GLBs/portraits only. The game plays skeletal clips,
projectiles, impacts and damage numbers. Older libraries are retained for the
world, commanders, story and legacy compatibility. Save user edits separately
before regeneration. Blender is not required to play.
