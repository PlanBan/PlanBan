extends SceneTree
var game: OrbitGame
var checks = 0
var failures = 0
const BASE = "user://qa_manual3d.json"
func _initialize() -> void: call_deferred("run")
func check(ok: bool, description: String) -> void:
	checks += 1
	if ok: print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
func equivalent(a: Variant, b: Variant) -> bool:
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size(): return false
		for key in a:
			if not b.has(key) or not equivalent(a[key], b[key]):
				print("SAVE MISMATCH ", key, " ", a[key], " / ", b.get(key))
				return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size(): return false
		for i in range(a.size()):
			if not equivalent(a[i], b[i]): return false
		return true
	if (a is int or a is float) and (b is int or b is float): return is_equal_approx(float(a), float(b))
	return a == b

func clean() -> void:
	for slot in range(1, 4):
		for suffix in ["", ".bak", ".tmp"]:
			var path = game.store.slot_path(slot) + suffix
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(BASE + ".prefs" + suffix): DirAccess.remove_absolute(BASE + ".prefs" + suffix)
func run() -> void:
	game = load("res://scenes/Orbit.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.music.stop()
	game.store.path = BASE
	game.store.settings_path = BASE + ".prefs"
	clean()
	check(game.state == "menu" and not game.active_campaign, "boot always opens menu without continuing a saved campaign")
	game.new_game()
	check(game.state == "dialogue" and game.story_index == 0 and game.store.data.completed.is_empty(), "New Game restarts the actual story")
	game.store.data.prologue_seen = true
	game.start_level(1)
	game.wave_wait = 1000
	game.selected = "core_reactor"
	game.deploy(Vector2i(0, 1))
	game.selected = "core_pulse"
	game.deploy(Vector2i(2, 2))
	game.spawn_enemy(2, "tank", 900)
	for i in range(130): game.advance(0.05)
	check(not game.orbs.is_empty() and not game.enemies.is_empty(), "snapshot contains a generator capsule and a surviving enemy")
	var before = game.snapshot()
	game.open_slots("save")
	check(game.state == "save" and game.return_state == "battle", "save panel freezes the battle")
	var battle_time = game.time
	game.advance(2)
	check(game.time == battle_time, "battle does not advance while choosing a slot")
	check(game.save_slot(1) and game.state == "battle" and not game.dirty, "manual save writes slot and returns to the same battle")
	var original = FileAccess.get_file_as_string(BASE)
	game.action("language", "de")
	check(FileAccess.get_file_as_string(BASE) == original and FileAccess.file_exists(BASE + ".prefs"), "changing preferences never writes campaign progress")
	game.energy = 0
	game.plants.clear()
	game.enemies.clear()
	game.orbs.clear()
	game.rng.seed = 7
	check(game.load_slot(1) and game.state == "pause", "battle load succeeds and pauses for the player")
	var after = game.snapshot()
	before.state = "pause"
	check(equivalent(before, after), "energy, positions, health, capsules, waves, timers, deck and RNG restore exactly")
	check(game.store.data.language == "de", "load keeps the current language and preferences")
	game.action("resume")
	for i in range(5): game.advance(0.05)
	check(game.time > battle_time and game.enemies[0].x < before.enemies[0].x, "restored battle resumes normally")
	game.action("menu")
	game.action("continue")
	check(game.state == "pause" and game.time > battle_time, "Continue from menu returns to the in-memory battle")
	game.return_state = "pause"
	check(game.save_slot(2), "second manual slot is independent")
	var second = FileAccess.get_file_as_string(game.store.slot_path(2))
	game.state = "pause"
	game.open_slots("save")
	game.action("slot", 1)
	check(game.pending_slot == 1 and FileAccess.get_file_as_string(BASE) == original, "overwriting an occupied slot requires an explicit button")
	game.action("cancel_overwrite")
	check(game.pending_slot == 0, "overwrite can be cancelled")
	game.action("slot", 1)
	game.action("overwrite")
	check(FileAccess.file_exists(BASE + ".bak") and FileAccess.get_file_as_string(game.store.slot_path(2)) == second, "atomic overwrite keeps a backup and other slots unchanged")
	var file = FileAccess.open(BASE, FileAccess.WRITE)
	file.store_string("{broken"); file.close()
	check(game.load_slot(1), "damaged primary save recovers from its previous valid backup")
	var valid = game.store.read_json(game.store.slot_path(2))
	valid.session.plants[0].bot.erase("timer")
	file = FileAccess.open(game.store.slot_path(3), FileAccess.WRITE)
	file.store_string(JSON.stringify(valid)); file.close()
	var current_time = game.time
	check(not game.load_slot(3) and game.time == current_time, "malformed battle data is rejected before touching the live session")
	game.new_game()
	check(game.store.data.completed.is_empty() and game.state == "dialogue" and FileAccess.get_file_as_string(game.store.slot_path(2)) == second, "New Game resets campaign but preserves all disk slots")
	game.start_level(1)
	game.finish(true)
	check(not game.store.data.completed.is_empty() and game.dirty and FileAccess.get_file_as_string(game.store.slot_path(2)) == second, "winning unlocks the reward in memory and waits for manual saving")
	check(game.save_slot(2), "victory can be saved explicitly")
	game.new_game()
	check(game.load_slot(2) and game.store.data.completed.has("1") and game.state == "victory", "saved victory and unlocked seed survive a new campaign")
	game.state = "battle"
	game.advance(0.05)
	game.quit_game()
	check(game.state == "exit_confirm" and not game.quitting, "quitting an unsaved battle offers save or return")
	game.action("quit_back")
	check(game.state == "battle", "exit confirmation can return to the active battle")
	game.action("settings")
	game.open_slots("save")
	check(game.snapshot().state == "pause", "saving from settings preserves the underlying paused battle")
	game.action("menu")
	game.action("continue")
	check(game.state == "settings", "Continue does not restore an orphan save panel")
	print("MANUAL SAVE RESULT: %d checks, %d failures" % [checks, failures])
	clean()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures == 0 else 1)
