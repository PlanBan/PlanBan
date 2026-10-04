extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game: OrbitGame = load("res://scenes/Orbit.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.music.stop()
	game.store.path = "user://qa_wave_checkpoint.json"
	game.store.data = OrbitProgress.defaults()
	game.store.data.sound = false
	game.start_level(1)
	game.wave_index = 1
	game.pending = game.mission.waves[0].duplicate(true)
	game.spawn_clock = 0.02
	game.spawn_enemy(1, "tank", 700)
	game.selected = "core_pulse"
	game.deploy(Vector2i(0,1))
	game.open_slots("save")
	assert(game.save_slot(1))
	game.pending.clear()
	game.enemies.clear()
	assert(game.load_slot(1) and game.state == "pause" and game.pending.size() == 3)
	game.action("resume")
	game.advance(0.05)
	assert(game.pending.size() == 2 and game.enemies.size() == 2 and game.enemies[1].row == 1 and game.enemies[1].kind == "drone")
	var fired = false
	for i in range(200):
		game.advance(0.05)
		fired = fired or not game.bullets.is_empty()
	assert(game.state == "battle" and game.pending.is_empty() and fired)
	print("RESUMED WAVE PASS: remaining queue spawns, restored bots shoot, float JSON fields work")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.store.path + suffix): DirAccess.remove_absolute(game.store.path + suffix)
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
