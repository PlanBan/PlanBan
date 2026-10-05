# Validation — Orbital Front 4.4 / Astra Forge

Verified with official Godot **4.7.2** and Blender **4.3.2**, 2026-10-05. This PC release replaces random card draw in new encounters with a player-edited command deck, adds an always-accessible supplies shop, aimed combat, fairer cold mechanics and sixteen original articulated machines. Historical lane-defense sources, older Blender libraries and the Android 4.1 APK are retained.

| Suite | Result | Coverage |
| --- | --- | --- |
| `tests/cards/rules.gd` | 30 checks, 0 failures | Owned commands, placement/costs, attack order, core damage, rewards, routes, invalid saves and backup recovery |
| `tests/cards/abilities.gd` | 40 checks, 0 failures | Legacy abilities, biome rules, boss phases, upgrades/remove/shop/rest/events and read-only migration |
| `tests/cards/desktop_rules.gd` | 31 checks, 0 failures | Guided practice/resumption, starters, tactical orders, shield/focus expiry, reactor/energy limits, reinforcement pacing and preferences |
| `tests/cards/research_rules.gd` | 37 checks, 0 failures | Twelve technology tiers, prerequisites/costs/world gates, core maximum 32, armour reduction, Aim/healing, pending legacy saves and ruleset 42 compatibility |
| `tests/cards/forge_rules.gd` | 46 checks, 0 failures | Editable 3–6 command deck, attackless/duplicate rejection, reserve rewards, exact shop prices, immediate item effects/no waste, generated robot UIDs, once-per-turn use/refresh, aimed damage, exact pending resumption, dismantling, corruption rejection, reported three-HP/three-damage regression, chill immunity, old-save migration, blueprint purchases, researched commands and future-only deck edits |
| `tests/cards/graphics.gd` | 204 checks, 0 failures | Real desktop mouse/drag/keyboard input, story/training, map zoom, research purchase, commander acceptance, inspection, orders, F5, pending reload, fullscreen/text settings, RU/EN/DE bounds and picking at four resolutions |
| `tests/cards/forge_graphics.gd` | 198 checks, 0 failures | Actual editor/shop/quickbar input, three chosen commands, fixed command position, duplicate-use rejection, cross-lane aim, pending reload, immediate repair, manufacture/dismantle, original rigs and all five clips, new portrait inspection, six nonoverlapping commands, RU/EN/DE previews at 125% text scale, eight pad projections at four resolutions |
| `tests/cards/journey.gd` | 75 actual encounters; 5 / 5 complete five-act victories | Owned-card selection, ordinary energy/technology/node costs, rewards, bosses and valid saved checkpoints |

The rule and rendering suites total **586 checks, zero failures**. Journey seeds 41293, 77183, 91022, 104812 and 51932 each finished with 26 core HP. The heuristic uses legal cards, purchases and orders; it does not alter HP, resources or damage to force a victory. These simulations establish viable routes, not universal balance. Visual fixtures used to show several robot roles are separate from ordinary campaign play.

## New encounter rules

Ruleset **44** snapshots the selected 3–6 owned blueprints and purchased technology. All selected commands are immediately visible, remain in fixed positions and refresh each turn. There is no random draw, discard cycling or reward inflation of the active deck. One command can be applied once per turn, with its normal energy cost. Generated units have independent UIDs and a validated reference to their owned blueprint. Deck edits during combat affect the following encounter, leaving the present snapshot unchanged.

Friendly attacks resolve first. Players can select a friendly attacker and then a live enemy in another lane; default targeting chooses the same lane or a remaining enemy. Normal attacks cannot bypass surviving enemies to reach the core. Dead units' queued attacks are skipped. Dismantling frees a pad and returns half the unit cost rounded down; it does not refresh an already used blueprint. Aim/Guard remain competing one-energy orders.

New Borea encounters have no blanket ice shield or periodic army freeze. Visible tanks retain shields. Ice runners chill only every third turn: minus one attack for one actual strike, with a brief immunity window. New Cryobot/Frost prism use weakening rather than a skipped attack. The regression test proves an ordinary three-HP enemy dies to three damage before it can retaliate or freeze. Existing shields, armour and guard reduction still apply visibly. EMP remains a distinct player disable action.

Supplies cost alloy: Nano repair 12 (+8 core HP), Energy cell 10 (+2 energy), Cleanser 8 (remove allied statuses), Strike drone 18 (two damage to all foes, with normal defences). Items apply immediately without spending energy, consume only on an effective use, persist through restart and are blocked during unresolved attacks. Repair also works on the map. A new run starts with one repair; old saves receive no free items. Known blueprints cost 22 + 8×rarity and enter reserve. All shop/deck changes use the existing atomic save path.

Energy starts at three, changes to four from turn four, receives at most one aggregate reactor bonus and caps at six. Technology retains four branches/three tiers at costs 18/36/60, world gates 1/2/3, researched core maximum 32, damage/HP/armour/energy and healing improvements. Core repair remains a repeatable selected command: cost two, heal eight; upgrades and research apply, with no full-health charge.

## Presentation and original models

The desktop uses a 1600×900 logical canvas, 1280×720 initial window, 1024×576 minimum and 90–125% text scale. Tests exercise 1280×720, 1600×900, 1920×1080 and 1024×576. Four circular manufacturing pads face four opposing pads with a full neutral row. Floating numeric HP/attack/defence replace name paragraphs on the field. Details appear on hover or free large inspection. HP is blue, attack red and defence yellow; role-specific metal/ceramic colours remain distinct when research adds armour.

**AstraForge.blend** is the fifth editable library, alongside AstraTabletop, AstraDioramas, AstraLibrary and AstraCommanders. `tools/generate_forge.py` creates nine friendly machine archetypes and seven opponents from original geometry, with named editable parts, rigid skeletal skin, sixteen GLBs and sixteen transparent Cycles portraits. Every export contains Idle/Deploy/Attack/Hit/Death. Godot checks all sixteen Skeleton3D rigs and eighty clips. Binary GLB checks also confirm each clip contains changing keyframe values, not empty/static animation labels. The game plays these clips alongside projectiles, impact sparks and floating damage numbers. New robots also appear in the opening scene. No downloaded game models or reference-extracted artwork are used.

Five original world dioramas, animated water/lava, traversal and opposing commanders are retained. Before each new fight the commander rises with a stable localised taunt; acceptance persists. Art is stylised and does not claim photorealistic equivalence to the supplied reference.

The original 48-second stereo 32 kHz melody and five tonal effects remain active. The former table hum is inactive. Music/master zero stops playback; music/effects/master are separate. Mesa llvmpipe/Xvfb and Dummy audio verify rendering and controls, not physical headphone listening quality.

## Exported executable and saved turns

The final exported Linux release was exercised with native X11/XTest input in an isolated profile. New game entered the story and actual guided practice; click and drag paid for Pulse/Reactor exactly once. Practice ended before the first campaign encounter. The visible editor removed three unwanted cards and saved the chosen Pulse/Core repair/Reactor loadout. The always-accessible shop charged twelve and ten alloy for repair/energy, and rejected full-health use without consuming an item.

The real route opened the opposing commander. Acceptance entered a ruleset 44 battle containing exactly those three chosen commands. Pulse manufacture preserved its blueprint; native clicks aimed it across lanes. Quick energy applied immediately and the Reactor cost was charged. F5 saved. The executable was quit during an unresolved turn, then restarted: the checkpoint was exactly equal as parsed run data. Continue completed the remaining queue, and the **entire resulting battle dictionary** matched an independently resolved expected checkpoint. Core was **19/20**, energy **4/4**, three commands remained in position and their once-per-turn use had reset. No damage or bonuses repeated. Quick repair restored 20/20 with no energy cost; the chosen Pulse built a second independently identified unit without waiting for random draw. Native deployment/turn GIFs contain 28 and 20 distinct rendered frames respectively.

Software-rendered cloud frames can make entrance controls available later than a wall-clock delay; native checks wait for actual state and repeat acceptance only while unaccepted. This timing accommodation does not alter HP, cards or resources.

Save format remains version 4. New fields are optional for older campaigns and strictly validated when present. An old campaign gains a 3–6 owned-card loadout and empty item inventory without healing. Already-started ruleset 41–43 encounters retain their saved hand, draw, energy, statuses and pending attacks until completion; subsequent encounters use 44. Legacy seven-card hands remain paginated. Global definitions can evolve; compatibility is not an immutable replay of every historical definition. New game resets expedition research, loadout and items while retaining permanent discoveries.

Manual F5/pause saves coexist with autosaves after committed actions and on pause/quit. Preferences are separate. Old orbit_progress.json and astra_slot_1*.json remain read-only migration sources. QA profiles do not modify a user's existing saves.

## Setup and distribution

The onboarding setup verifies the official Godot archive/executable, imports a disposable copy and runs all five headless suites (30+40+31+37+46). It preserves the working checkout and unrelated projects/services. Reusable setup/start instructions are saved in the environment configuration draft; applying/publishing that draft is separate from publishing the game.

Windows/Linux x86_64 use official Godot 4.7.2 release templates. Linux is exercised here; physical Windows execution is not verified. Desktop ZIPs contain 4.4; the historical mobile APK stays 4.1.

Source ZIPs exclude .godot/build/cache/profile data, Blender backups and signing keys. Diorama textures are embedded in GLBs and packed into the library; clean import regenerates all 42 texture copies identically. Delivery checks validate all five libraries, sixteen new GLBs/portraits, commander/world assets, clean source import and the headless suites, executable/source identity, ZIP CRC, SHA256 and GitHub's 100 MiB file limit. Published ZIPs/previews are downloaded independently and compared with local artifacts.
