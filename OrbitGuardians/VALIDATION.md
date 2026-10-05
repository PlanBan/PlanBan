# Validation — Orbital Front 4.0 / Astra Tabletop

Verified on Linux with official Godot **4.7.2** and Blender **4.3.2**, 2026-10-05. This report concerns the new card game, not the retained lane-defense source.

| Suite | Result | What it exercises |
| --- | --- | --- |
| `tests/cards/rules.gd` | 30 checks, 0 failures | Opening hand, legal placement, costs, attack order, core damage, shield/freeze/repair/recall, rewards, branches, invalid saves and backup recovery |
| `tests/cards/abilities.gd` | 40 checks, 0 failures | All robot/action abilities, spendable kill refund, jam duration, temporary shields, five biome rules, boss phase, upgrade/remove/shop/rest/events, read-only legacy migration and unchanged starter power |
| `tests/cards/graphics.gd` | 69 checks, 0 failures | Real 3D rendering and injected touch/drag input, second-finger handling, same card moving to the board, large card inspection, unfinished-turn autosave, ordinary victory/reward/route, German settings slider, five environments, projection at 480×854 / 720×1280 / 960×720 / 390×844 |
| `tests/cards/journey.gd` | 69 real encounters; 3 of 5 complete five-act victories | Normal starter decks, real energy costs, turn resolution, upgrades, shops, events, rewards, all five bosses and ending; every checkpoint validates |

The journey test uses a heuristic player. It does not change enemy health, player energy, damage, turns or rewards to force victories. Seeds: 41293, 77183, 91022, 104812, 51932. Two runs lost, as expected in a roguelike; three reached the ending. This demonstrates viable routes, not perfect game balance.

Blender generated **46 original GLBs** and **45 portraits**, plus `AstraTabletop.blend`. Meshes in each static exported model are merged while editable originals keep separate named parts. The previous 54 GLBs and `AstraLibrary.blend` are retained. Card movement, deployment, attack lunges, death shrink/fall, hit sparks, miniatures, lamp flicker, hologram ships and planet rotation are rendered by Godot; the screenshots are captured from the running game.

Save checkpoints include run deck identities/upgrades, current branch, visited nodes, events/stock/rewards, currencies, core health, combat zones, status effects, reinforcement intent, remaining attacks and two random-generator states encoded as strings. A reload during combat resumes the remaining queue. Preferences remain separate. Legacy manual slots are read but never rewritten. New runs clear run-local power while retaining the archive.

The Linux executable was exercised through native X11/XTest mouse input: new expedition, story, route, tap-to-slot, drag Reactor, single energy charge, pause/quit during turn resolution, and continuation after restarting the executable. Windows x86_64 is exported using the official release template; it is not executed under Windows here.

Android APK uses the official debug template, package `com.planban.orbitalfront`, version 400 / 4.0.0, ARM64, minimum API 24, target API 36, portrait orientation. APK Signature Schemes v2 and v3 verify with `apksigner`; `aapt` confirms metadata and portrait mode. No internet permission is declared. It is a development-signed build, not a store release. No physical Android device, Android emulator or iOS build was used, so device performance and platform-specific lifecycle behavior remain unverified. The injected touch tests exercise the real game input path on Linux.

Graphical validation uses Mesa llvmpipe/Xvfb and Dummy audio. Volume persistence and audio channel controls work; listening quality and mobile frame rates are not established by these tests. Android device discovery through the optional ADB tool cannot create its cache under the cloud's read-only home; this does not prevent APK export/signature verification. Game resources and user profiles are separate.

Source archives exclude `.godot`, builds, Blender backups, cloud tools, signing keys and profile saves. ZIP structure and CRC checks, archive SHA256 values and published downloads are verified. For development, inspect this report alongside `README.md`; the old test suites remain available only for the old mechanics.
