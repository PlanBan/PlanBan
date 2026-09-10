# Abandoned Jungle Ruins — editable Godot project

Target: Godot 4.7.2.

The project is intentionally organized around editable Godot scenes/resources. Level geometry, sprites, animations, buttons and audio should live in `.tscn` scenes and resources instead of being drawn/generated from GDScript.

Folders:
- `scenes/menu` — main menu and animated background
- `scenes/player` — player scene
- `scenes/enemies` — enemy scenes
- `scenes/levels` — playable levels
- `scenes/ui` — HUD/overlays
- `scenes/props` — reusable jungle/ruin props
- `assets` — local images/audio
- `resources` — reusable Godot resources
- `scripts` — only gameplay logic that cannot be expressed cleanly as scene data
- `docs` — asset/license/editing notes
