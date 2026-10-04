extends SceneTree
## Run with a graphics display; captures the actual rendered project and tests input.
var game: OrbitGame
var output = "user://captures"
const SAVE = "user://qa_ui_v2.json"
func _initialize() -> void: call_deferred("run")
func frame() -> void:
	if game != null and is_instance_valid(game): game.view.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
func snapshot(name: String) -> void:
	game.view.queue_redraw()
	await frame()
	assert(root.get_texture().get_image().save_png(output + "/OrbitGuardians-v2-" + name + ".png") == OK)
func key(code: int) -> void:
	var event = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await frame()
func mouse(point: Vector2, pressed: bool) -> void:
	var global_point = game.to_global(point)
	root.warp_mouse(global_point)
	await frame()
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = global_point
	event.global_position = global_point
	Input.parse_input_event(event)
	await frame()
func click(point: Vector2) -> void:
	await mouse(point, true)
	await mouse(point, false)
func run() -> void:
	if OS.get_environment("ORBIT_CAPTURE_DIR") != "": output = OS.get_environment("ORBIT_CAPTURE_DIR")
	DirAccess.make_dir_recursive_absolute(output)
	game = load("res://scenes/Orbit.tscn").instantiate()
	root.add_child(game)
	await frame()
	game.store.path = SAVE
	game.store.data = OrbitProgress.defaults()
	game.apply_settings()
	game.music.stop()
	await snapshot("menu-ru")
	await click(Vector2(1250, 53))
	assert(game.store.data.language == "en", "language button selects English")
	await snapshot("menu-en")
	await key(KEY_ENTER)
	assert(game.state == "dialogue", "Enter begins story")
	game.story_clock = 20
	await snapshot("dialogue-en")
	while game.state == "dialogue":
		game.story_clock = 100
		await key(KEY_ENTER)
	assert(game.prologue and game.state == "battle")
	await snapshot("prologue")
	game.set_process(false)
	for i in range(660): game.advance(0.05)
	assert(game.state == "cinematic")
	game.scene_clock = 2.0
	await snapshot("theft")
	game.begin_story("theft")
	while game.state == "dialogue":
		game.story_clock = 100
		await key(KEY_ENTER)
	assert(game.state == "travel")
	await snapshot("travel")
	await key(KEY_ENTER)
	assert(game.state == "briefing")
	await key(KEY_ENTER)
	await key(KEY_2)
	await click(game.center(Vector2i(0, 1)))
	assert(game.plants.has(Vector2i(0, 1)), "offset viewport mouse deploys reactor")
	await key(KEY_SPACE)
	assert(game.state == "pause")
	await click(Vector2(720, 434))
	assert(game.state == "battle")
	game.action("settings")
	await frame()
	await mouse(Vector2(403.5, 406), true)
	assert(game.slider_key == "music_volume")
	root.warp_mouse(game.to_global(Vector2(269.75, 406)))
	await frame()
	var motion = InputEventMouseMotion.new()
	motion.position = game.to_global(Vector2(269.75, 406))
	Input.parse_input_event(motion)
	await frame()
	await mouse(Vector2(269.75, 406), false)
	assert(absf(game.store.data.music_volume - 0.25) < 0.003, "slider drag updates music volume")
	var restored = OrbitProgress.new()
	restored.path = SAVE
	restored.load_progress()
	assert(is_equal_approx(restored.data.music_volume, game.store.data.music_volume), "slider release persists volume")
	await snapshot("settings-en")
	game.action("fullscreen")
	await frame()
	assert(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	game.action("fullscreen")
	await frame()
	assert(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED)
	print("PASS: actual story input, offset grid clicks, pause/resume, slider drag/save and fullscreen toggle")
	for i in range(1, 51): game.store.data.completed[str(i)] = 3
	game.store.data.deck = ["core_pulse", "seed_25", "seed_26", "seed_20", "seed_23", "seed_21"]
	for language in ["ru", "en", "de"]:
		OrbitLocale.cache.clear()
		OrbitLocale.missing.clear()
		game.store.data.language = language
		for screen in ["menu", "settings", "map", "hangar", "briefing", "dialogue", "travel", "cinematic", "battle", "pause", "victory", "defeat"]:
			game.state = screen
			game.level_page = 1
			game.mission = OrbitContent.level(12)
			if screen == "dialogue":
				game.begin_story("theft")
				game.story_clock = 100
			if screen == "battle":
				game.start_level(12)
				game.spawn_enemy(2, "runner", 1100)
			if screen == "victory":
				game.reward_new = true
				game.earned_stars = 3
			await frame()
			if language == "de" and screen in ["menu", "settings", "hangar", "briefing"]: await snapshot(screen + "-de")
		assert(OrbitLocale.missing.is_empty(), "untranslated labels: " + str(OrbitLocale.missing))
		print("PASS: all 12 screens rendered in " + language + " without missing translations")
	game.store.data.language = "ru"
	for sector in range(5):
		game.level_page = sector
		game.state = "map"
		await snapshot("map-%d" % sector)
		game.start_level(sector * 10 + 3)
		game.energy = 10000
		for row in range(5):
			for col in [0, 2, 6]:
				var id: String = "seed_25" if col == 0 else ("core_pulse" if col == 2 else "seed_26")
				game.selected = id
				game.cooldowns[id] = 0
				game.deploy(Vector2i(col, row))
			game.spawn_enemy(row, ["drone", "runner", "tank", "disruptor", "boss"][row], 1020 + row * 38)
		game.add_energy(Vector2(705, 436), 45)
		game.energy = 230
		game.wave_index = 2
		game.toast_time = 0
		await snapshot("planet-%d" % sector)
	print("UI RESULT: input checks and 3 languages / 5 planets passed")
	game.queue_free()
	await frame()
	await create_timer(0.2).timeout
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SAVE + suffix): DirAccess.remove_absolute(SAVE + suffix)
	quit(0)
