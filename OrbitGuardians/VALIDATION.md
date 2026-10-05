# Validation — Orbital Front 4.3 / Desktop

Verified with official Godot **4.7.2** and Blender **4.3.2**, 2026-10-05. This desktop update adds closer cameras, coloured robot roles, core healing, expedition technology and five opposing commanders. Historical lane-defense sources and the Android 4.1 APK are retained.

| Suite | Result | What it exercises |
| --- | --- | --- |
| `tests/cards/rules.gd` | 30 checks, 0 failures | Owned opening cards, placement/costs, attack order, core damage, rewards, route choices, invalid saves and backup recovery |
| `tests/cards/abilities.gd` | 40 checks, 0 failures | Robot/action abilities, five biome rules, boss phase, card upgrades/remove/shop/rest/events and read-only legacy migration |
| `tests/cards/desktop_rules.gd` | 31 checks, 0 failures | Training gates/resumption, small starters, tactical orders, temporary shield/focus, aggregated reactors, hand/energy limits, reinforcement pacing and preferences |
| `tests/cards/research_rules.gd` | 37 checks, 0 failures | All twelve technology tiers, real costs/prerequisites/world gates, maximum core 32, armour damage reduction, stronger Aim, heal amounts/cost/clamping/full-health rejection, pending save/resume without doubled bonuses, old save migration and ruleset 42 compatibility |
| `tests/cards/graphics.gd` | 204 checks, 0 failures | Actual desktop mouse/drag/keyboard input, story/training, map zoom without route mutation, buying research, commander entrance/acceptance, inspection/colours, orders, F5, pending-resolution reload, text/fullscreen settings, RU/EN/DE bounds and route/slot projection at four window sizes |
| `tests/cards/journey.gd` | 75 actual encounters; 5 of 5 complete five-act victories | Ordinary card/technology costs, tactical orders, shops, events, rewards, upgraded core and all bosses; save checkpoints validate |

The suites total **342 checks, zero failures**, plus campaign simulations. Journey seeds 41293, 77183, 91022, 104812 and 51932 finished with 32, 28, 32, 17 and 11 core HP respectively. The heuristic player uses real owned cards and legal purchases/orders. It does not alter health, resources or damage to force victories; rendering fixtures are separate from campaign simulations. These runs establish viable routes; human play feedback remains useful for difficulty tuning.

## Presentation and new rules

The desktop uses a 1600×900 logical canvas, 1280×720 initial window and 1024×576 enforced minimum, with 16:9 aspect and 90–125% text scale. Graphical checks cover 1280×720, 1600×900, 1920×1080 and 1024×576. A complete neutral row separates the armies. Five hand cards fit side by side. Inspection remains free.

The map initially zooms to 125%, adjustable from 100–140% with the wheel or +/- controls; dragging pans it. Battle camera size changes from 14.5 to 12.1, with enlarged 3D miniatures. HP is blue, attack red and shields/armour yellow; role materials are duplicated per instance so shared assets are not recoloured globally. Vector hearts and segmented core bars show actual researched maxima. Defensive units are yellow, repairs green, energy teal and weapons warm/purple.

Normal new encounters start with three owned cards and three energy. Base energy is 3 for turns 1–3 and 4 afterwards; all reactors together add at most one, total available energy caps at six. Draw is one per turn and hand limit five. The six-card starter includes Core repair (cost 2, heal 8); card upgrades reduce cost and add four healing each, and the rescue technology adds four more. Full-health play is rejected before consuming energy/card. Technology has four branches and three sequential tiers at costs 18/36/60, gated to worlds 1/2/3. It resets on New game and persists for the current expedition.

Five original 3D commanders enter with a rising/scaling animation before normal battles; each has three localised taunts. The player accepts the dialogue to begin. The selected taunt and accepted state persist, so resuming an already accepted battle avoids replaying the introduction. The commander portrait remains beside combat until card hovering displays the coloured statistics instead. The opening story and one-card guided tutorial from 4.2 remain available.

## Native release and saved turns

The final exported Linux executable was exercised using native X11/XTest input in an isolated profile. New game led through story and real guided practice into the first route. Mouse-wheel zoom preserved route data; a core technology purchase charged 18 alloy and raised actual HP to 24. Confirming travel opened the commander, whose acceptance led to a three-energy opening. Pulse and Reactor were both paid for on turn one. F5 recorded the deployment.

The executable was quit with four unresolved operations. Restarting preserved the exact checkpoint; Continue resolved it to core **23/24**, opposing core **18/20**, turn 2, energy **4/4** and two hand cards, retaining research without duplicated damage or replayed dialogue. Normal play drew the owned Core repair; its UI confirmation healed the core to its researched maximum and charged exactly two energy. Final screenshots and the GIF come from the application. Native timing waits account for software-rendered cloud frames.

Save schemas remain format version 4. New encounters use ruleset 43 and snapshot the purchased technology. Old run saves receive an empty tree without healing; unresolved ruleset 41/42 encounters retain their stored zones, statuses, attack queues and former energy/draw rules. Global card definitions can evolve; this is save compatibility rather than an immutable replay of every historical definition. A seven-card legacy hand is paginated. Expanded maximum core is validated against purchased core tiers. New-game resets expedition buffs while retaining the archive.

Manual F5/pause saves coexist with autosaves after each committed action and on pause/quit. Preferences are separate. Old orbit_progress.json and astra_slot_1*.json are read-only achievement migration sources. QA uses separate profiles and paths; user saves are not deleted to pass tests.

## Original models and audio

Four editable libraries are included: AstraTabletop.blend, AstraDioramas.blend, AstraLibrary.blend and the new **AstraCommanders.blend**. Existing tabletop assets include 46 GLBs/45 portraits, and diorama assets nine GLBs (five worlds, desk, token, gate, explorer). The new library adds five commander GLBs, five commander portraits and nine colour role portraits; tools/generate_commanders.py reproduces them from original geometry. No purchased/reference-extracted game assets are used. The explorer has Idle/Walk/Attack/Deploy/Death clips. Paths use MultiMesh; water/lava animate in shaders. Art is stylised, not a photorealistic recreation of the supplied reference.

The original 48-second PCM16 stereo 32 kHz melody and five tonal effects from 4.2 remain active; the former table_hum is inactive. Their generation uses no random-noise layer. Music stops at zero volume, with separate master/music/effects controls. Mesa llvmpipe/Xvfb and Dummy audio allow rendering and control tests, not physical headphone listening verification.

## Setup, export and distribution

The onboarding installation is checked on a disposable copy using the verified official Godot archive, a fresh import and all four headless suites (30 + 40 + 31 + 37). Setup preserves the working checkout and unrelated projects/services. Reusable commands and startup instructions are saved in the environment configuration draft; publishing that environment draft is separate from the game release.

Windows and Linux x86_64 are exported with official Godot 4.7.2 release templates. The Linux executable is exercised here. Windows is built and checked as a file; physical Windows execution is not verified. Desktop ZIPs contain version 4.3; the historical mobile APK remains 4.1.

Source archives exclude .godot/build/cache/profile data, Blender backups and signing keys. Diorama textures are embedded in GLBs and packed into the editable library; Godot regenerates their standalone copies on clean import. Distribution checks validate all four libraries, five commander GLBs, clean source import and headless suites, 42 identically regenerated textures, executable/source identity, ZIP CRC, SHA256 and GitHub's 100 MiB per-file limit. Published archives are downloaded independently and compared byte for byte.
