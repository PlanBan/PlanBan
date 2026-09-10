# V2 validation report

Target engine: Godot 4.7.2 stable.

Checks completed before packaging:
- All `res://` references used by project/scenes/scripts resolve to files in the project.
- All `.tscn` ExtResource/SubResource ids resolve; `load_steps` counts were checked and corrected.
- Main menu contains exactly two Button nodes: `PLAY` and `QUIT`.
- Signal connection methods referenced by scenes exist in their scripts.
- Basic GDScript structural checks passed (balanced brackets/parentheses and required `extends`).
- All SVG assets parse as valid XML/SVG.
- All WAV files open as valid PCM audio.
- Jungle ambience probes as a valid Vorbis OGG stream (mono, 22050 Hz, 8 seconds).
- Known Godot 4.7 Area2D physics-lock issue is avoided for relic and exit-gate monitoring by using deferred property changes.
- Default jump physics gives an apex of about 132 px and full-air horizontal travel of about 228 px; the intended platform route stays below those reach limits.
- ZIP is extracted to a fresh temporary directory and the same resource/reference checks are repeated.

Environment note: this build environment does not have a runnable Godot 4.7.2 editor binary, so an actual engine boot/render playtest cannot be executed here. The project was therefore checked statically and structurally before packaging; the previous user-side project already reached runtime, and the V2 fixes avoid the specific runtime errors reported there.
