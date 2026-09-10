# V2 checkpoint

Target: Godot 4.7.2 stable.

V2 changes:
- Reworked visual direction toward darker abandoned jungle / lost temple ruins.
- Replaced the old player look with a dedicated explorer sprite set.
- Reworked melee: only the machete/attack arc swings; the entire character no longer rotates.
- Attack hitbox follows the facing direction.
- Increased jump reliability and added coyote time + jump input buffering.
- Lowered/normalized level platform heights so the intended route is comfortably reachable.
- Fixed the Godot 4.7 `Area2D.monitoring` error on relic pickup.
- Deferred exit-gate monitoring changes too, preventing the same physics-lock error when the last relic is collected.
- Fixed bee hurt animation so surviving enemies return to their fly animation.
- Game-over now freezes enemy movement behind the overlay.
- Prevented duplicate menu actions from rapid double-clicking and added default keyboard focus to Play.
- Added editable SFX and looping jungle ambience nodes/resources.
