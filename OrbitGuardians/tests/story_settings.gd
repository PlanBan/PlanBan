extends SceneTree
var game: OrbitGame
var checks = 0
var failures = 0
const PATH = "user://qa_story_settings.json"
func _initialize() -> void: call_deferred("run")
func check(ok: bool, description: String) -> void:
	checks += 1
	if ok: print("PASS: " + description)
	else:
		failures += 1
		push_error(description)
func finish_dialogue() -> void:
	while game.state == "dialogue":
		game.story_clock = 100.0
		game.advance_story()
func run() -> void:
	game = load("res://scenes/Orbit.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.music.stop()
	game.store.path = PATH
	game.store.data = OrbitProgress.defaults()
	game.store.data.sound = false
	game.action("continue")
	check(game.state == "dialogue" and game.story_context == "intro", "fresh campaign opens the story")
	game.advance_story()
	check(game.story_index == 0 and game.story_clock > 0, "first input reveals the whole line")
	finish_dialogue()
	check(game.prologue and game.mission.number == 0 and game.state == "battle", "intro starts a playable prologue")
	for i in range(660): game.advance(0.05)
	check(game.state == "cinematic" and game.store.data.completed.is_empty() and game.store.unlocked().size() == 3, "prologue inevitably loses without granting campaign rewards")
	game._process(9.1)
	check(game.state == "dialogue" and game.story_context == "theft", "core theft leads to pursuit dialogue")
	finish_dialogue()
	check(game.store.data.prologue_seen and game.state == "travel" and game.travel_target == 1, "pursuit saves story completion and launches the journey")
	game.action("travel_skip")
	check(game.state == "briefing" and game.mission.number == 1, "travel leads to first mission briefing")
	game.action("launch")
	game.finish(true)
	game.action("next")
	check(game.state == "travel" and game.travel_target == 2 and game.store.unlocked().size() == 4, "victory grants a seed and next launches the ship")
	game.store.data.language = "de"
	game.store.data.music_volume = 0.0
	game.store.data.effects_volume = 0.42
	game.store.data.master_volume = 0.75
	game.store.save_progress()
	var restored = OrbitProgress.new()
	restored.path = PATH
	restored.load_progress()
	check(restored.data.prologue_seen and restored.data.language == "de" and is_equal_approx(restored.data.effects_volume, 0.42) and restored.data.music_volume == 0.0, "language, story and independent volumes survive restart")
	game.apply_settings()
	check(game.music.volume_db <= -80 and game.sound_players.deploy.volume_db <= -80, "global mute silences both channels")
	game.store.data.sound = true
	game.apply_settings()
	check(game.music.volume_db <= -80 and game.sound_players.deploy.volume_db > -30, "music can be muted while effects remain audible")
	game.state = "battle"
	game.action("settings")
	var before = game.time
	game.advance(2)
	game.action("settings_back")
	check(game.state == "pause" and game.time == before, "settings pause the battle and return to pause")
	var file = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "completed": {"1": 3, "2": 2, "3": 1}, "deck": ["seed_01", "core_reactor"], "sound": false}))
	file.close()
	restored.load_progress()
	check(restored.data.completed.size() == 3 and restored.next_level() == 4 and restored.data.deck == ["seed_01", "core_reactor"] and restored.data.language == "ru", "v1 saves migrate with all rewards and deck preserved")
	game.store.data = OrbitProgress.defaults()
	for i in range(1, 50): game.store.data.completed[str(i)] = 3
	game.start_level(50)
	game.finish(true)
	game.action("next")
	check(game.state == "dialogue" and game.story_context == "ending", "final mission has a story ending")
	finish_dialogue()
	check(game.store.data.core_recovered and game.state == "menu" and game.store.unlocked().size() == 53, "ending restores Astra and retains all 53 seeds")
	for language in ["en", "de"]:
		OrbitLocale.missing.clear()
		for source in OrbitLocale.STRINGS:
			if "%" not in source: OrbitLocale.translate(source, language)
		check(OrbitLocale.translate("МИССИЯ 12 · Ледяной каньон", language) == ("MISSION 12 · Ice canyon" if language == "en" else "MISSION 12 · Eisschlucht"), "formatted mission names translate into " + language)
		check(OrbitLocale.translate("Криобот · 01", language) == ("Cryobot · 01" if language == "en" else "Kryobot · 01"), "seed names translate into " + language)
		check(OrbitLocale.missing.is_empty(), "all dictionary labels translate into " + language)
	for n in range(5):
		game.start_level(n * 10 + 1)
		game.spawn_enemy(1, "runner", 1000)
		var enemy: Dictionary = game.enemies[0]
		if n == 1:
			var hp: float = enemy.hp
			game.damage_enemy(enemy, 1)
			check(enemy.hp == hp and enemy.shield > 0, "ice crystal shield absorbs damage before armor")
		if n == 4:
			enemy.biome_clock = 0.01
			game._update_enemies(0.02)
			check(enemy.row == 2, "Nexus quantum runners change lanes")
		check(game.art.has(game.enemy_art("runner")), "planet %d has its own enemy art" % (n + 1))
	print("STORY/SETTINGS RESULT: %d checks, %d failures" % [checks, failures])
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix): DirAccess.remove_absolute(PATH + suffix)
	quit(0 if failures == 0 else 1)
