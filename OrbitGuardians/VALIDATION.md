# Validation — Orbital Front 4.2 / Desktop

Verified on Linux with official Godot **4.7.2** and Blender **4.3.2**, 2026-10-05. This release changes the active card game to a 16:9 PC layout and paced tactical combat. Historical lane-defense sources and the published 4.1 mobile APK are retained.

| Suite | Result | What it exercises |
| --- | --- | --- |
| `tests/cards/rules.gd` | 30 checks, 0 failures | Opening hand, placement, costs, attack order, core damage, shield/freeze/repair/recall, rewards, branches, invalid saves and backup recovery |
| `tests/cards/abilities.gd` | 40 checks, 0 failures | Robot/action abilities, kill refund, jam and temporary shields, five biome rules, boss phase, upgrades/remove/shop/rest/events and read-only legacy migration |
| `tests/cards/desktop_rules.gd` | 31 checks, 0 failures | Guided practice gates and resumption, owned training cards, six-card starters, orders and costs, one order per bot/turn, one-strike focus, shield absorption/expiry, aggregated reactor generation, energy/hand caps, paced reinforcements, old encounter rules and UI preference sanitation |
| `tests/cards/graphics.gd` | 186 checks, 0 failures | Real 1280×720 mouse input, four animated story scenes, complete guided practice including Reactor drag, route preview/confirmation, card inspector/E/wheel, orders, F5, pending-resolution reload, victory/reward, text scaling/fullscreen, RU/EN/DE large-text bounds, five maps and every route/slot projection at four PC window sizes |
| `tests/cards/journey.gd` | 75 real encounters; 2 of 5 complete five-act victories | Ordinary costs and tactical orders, all five acts/bosses, upgrades/shops/events/rewards and ending; checkpoints validate |

The automated suites total **287 checks** without failures, plus the campaign simulations. The heuristic journey player uses real starter decks, card costs and one-energy orders; it does not modify health, energy, turns, damage or rewards to force wins. Seeds 77183 and 91022 completed all five acts with 4 and 8 core HP. Seeds 41293, 104812 and 51932 lost in act five. This establishes viable campaigns and leaves room for more human balance feedback.

## Desktop and presentation

Logical resolution is 1600×900, initial window 1280×720, minimum window 1024×576; the root Window enforces the minimum. Resizing and F11 retain the 16:9 composition. The graphical suite checks 1280×720, 1600×900, 1920×1080 and 1024×576. Text scale persists between 90% and 125%. RU/EN/DE tutorial/story and preview text bounds are checked at the large-text setting.

The hand is flat and nonoverlapping, with five visible cards per page. Board robots are 3D miniatures with separate readable names, ATK and current/max HP. A full neutral row separates the armies. Core and energy bars use separate labels/numbers and a clamped fill. New encounters start with three cards/two energy, draw one, cap hand at five and energy at five. The opening tutorial introduces one owned card at a time and does not consume the first campaign encounter or award extra cards.

Four story chapters use actual moving ships, attacks, fallen defenders, a moving core and an escape. The scene advance button waits for its animation; story skipping opens practice rather than dropping the player into an unexplained full hand. Inspection renders a large card and wrapped description without spending energy. Transient route selection and the world overview do not alter campaign progress.

## Native release and saved turns

The exported Linux release was exercised through native X11/XTest input: menu/new game, story-to-practice, Pulse placement, Reactor drag, completion before the first route encounter, preview/confirmed travel, ordinary three-card opening, deployment, tactical Guard, explicit F5, pause/quit with unresolved attacks and continuation after restarting the executable. Native screenshots and a recording are captured from the real application. The remaining attack queue resumes without repeating completed damage.

Save formats remain version 4. Checkpoints include card identities/upgrades, branch/visited nodes, currencies, deck zones, core and bot health, temporary statuses, focus/orders, reinforcement intentions, remaining attacks and random-generator states. New encounters use ruleset 42. Restored old encounters without that field use ruleset 41, retaining their saved hand, energy and older draw behavior until the encounter ends. A legacy hand of seven is displayed as pages of five and two. Global card definitions are updated in 4.2; compatibility concerns saved progress and unresolved combat, rather than an immutable replay of all historical card definitions.

Manual F5/pause saves coexist with autosaves after each committed action/resolution and on pause/quit. Preferences remain separate. Legacy campaign/manual-slot files are read for achievements and never overwritten. New journeys reset run-local power and retain the archive.

## Assets and audio

The existing original Blender assets remain included: `AstraTabletop.blend` (46 GLBs/45 portraits), `AstraDioramas.blend` (nine GLBs: five worlds, command desk, token, gate and explorer), and `AstraLibrary.blend`. The explorer has Idle/Walk/Attack/Deploy/Death skeletal clips. Its corrected 572 hand/knuckle vertices follow the corresponding arm joints. Tokens/paths use MultiMesh, and water/lava use animated shaders. The art is an original stylised interpretation of the supplied tabletop reference; no reference-image overlay is used.

`tools/generate_desktop_audio.py` creates the new original **48-second PCM16 stereo 32 kHz** musical loop and five tonal effects. Its melody, bass and arpeggios replace the old continuous `table_hum`, which is inactive. Samples contain no random-noise layer, NaNs or clipping; measured peak is 0.63 and RMS approximately 0.163. The suite checks channel controls, zero-volume stopping and persisted settings. Rendering uses Mesa llvmpipe/Xvfb and Dummy audio: physical speaker/headphone listening quality is not established by the cloud checks.

## Setup, exports and distribution

The onboarding setup passed on a new disposable copy: official Godot archive/executable checksum verification, clean import, 30 rules, 40 ability and 31 desktop rules checks. It preserves the development checkout and unrelated projects/services. Reusable setup/start instructions are saved in the environment configuration draft.

Windows x86_64 and Linux x86_64 are exported using official Godot 4.7.2 release templates. Linux release execution is tested here; the Windows executable is built and checked as a file, with no physical Windows execution. Version 4.2 packages Windows and source only. The historical Android 4.1 APK is not rebuilt or relabeled as a desktop update.

Source archives exclude `.godot`, builds, Blender backups, signing keys, cloud tools and profile data. Diorama images remain embedded in GLBs and packed in `AstraDioramas.blend`; duplicate PNG copies are regenerated by clean Godot import. All three editable libraries are included. Distribution verification checks source/executable identity, clean source import and rule suites, embedded-texture regeneration, ZIP CRC, SHA256 and GitHub's 100 MiB per-file limit. Published downloads are independently compared to the packaged bytes.
