# Prologue hotfix checkpoint — 2026-09-11

This checkpoint continues Stage 4 without advancing ROADMAP Stage 5.

Completed locally and validated:
- refreshed four-room prologue based on the user's supplied visual references;
- automatic path transitions between MainCrossing, NorthSanctum, SouthShrine and HermitPath;
- Hermit German dialogue and progression flag `spoke_to_hermit`;
- automatic north rune exit into existing MossEntrance after the Hermit conversation;
- RoomExit re-arm guard: if the player spawns inside an exit trigger, that exit remains disarmed until the player first leaves its Area2D, then it can trigger only after re-entering;
- `battle_scene.gd` parser hotfix: removed the typed `for button: Button in buttons` iterator syntax and simplified button arrays for Godot 4.7.2 parser compatibility;
- corrected prologue TSCN `load_steps` and Camera2D override indices;
- static validation: 0 missing `res://` resources, 0 TSCN load-step mismatches, no remaining typed for-loop parser hazard, RoomExit body_entered/body_exited connections present.

Important: Godot 4.7.2 executable is not available in the build container, so runtime engine boot testing still requires the user's local Godot.

Next after user confirms this hotfix: continue ROADMAP Stage 5 `Glasgarten`.
