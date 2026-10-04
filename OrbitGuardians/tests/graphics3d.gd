extends SceneTree
## Real OpenGL rendering, UI clicks, resized viewport picking and skeletal movement.
var game: OrbitGame
var failures = 0
var checks = 0
var output = "user://captures3d"
func _initialize() -> void: call_deferred("run")
func check(ok: bool, description: String) -> void:
	checks += 1
	if ok: print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
func frame() -> void:
	game.view.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
func shot(name: String) -> void:
	await frame()
	assert(root.get_texture().get_image().save_png(output + "/OrbitGuardians-v3-" + name + ".png") == OK)
func key(code: int) -> void:
	var event = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await frame()
func click(point: Vector2) -> void:
	var pixel = game.get_global_transform_with_canvas() * point
	root.warp_mouse(pixel)
	await frame()
	for pressed in [true, false]:
		var event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = pixel
		event.global_position = pixel
		Input.parse_input_event(event)
		await frame()
func button(command: String, value: Variant = null) -> void:
	await frame()
	for item in game.view.buttons:
		if item.action == command and (value == null or item.get("value") == value):
			await click(item.rect.get_center())
			return
	check(false, "button exists: " + command)
func run() -> void:
	if OS.get_environment("ORBIT_CAPTURE_DIR") != "": output = OS.get_environment("ORBIT_CAPTURE_DIR")
	DirAccess.make_dir_recursive_absolute(output)
	game = load("res://scenes/Orbit.tscn").instantiate()
	root.add_child(game)
	await frame()
	game.store.path = "user://qa_graphics3d.json"
	game.store.settings_path = "user://qa_graphics3d.prefs"
	game.store.data = OrbitProgress.defaults()
	game.apply_settings()
	game.music.stop()
	await shot("menu")
	await button("new_game")
	check(game.state == "dialogue" and game.active_campaign, "New Game menu button begins the story")
	game.story_clock = 100
	await shot("intro")
	while game.state == "dialogue":
		game.story_clock = 100
		await key(KEY_ENTER)
	check(game.prologue and game.state == "battle", "dialogue input opens the actual 3D prologue")
	game.set_process(false)
	for i in range(660): game.advance(0.05)
	check(game.state == "cinematic", "prologue loss starts a 3D core theft")
	game.scene_clock = 4
	await shot("theft")
	game.begin_story("theft")
	while game.state == "dialogue":
		game.story_clock = 100
		await key(KEY_ENTER)
	await shot("travel")
	await key(KEY_ENTER)
	await key(KEY_ENTER)
	game.wave_wait = 1000
	await frame()
	for resolution in [Vector2i(1280,720), Vector2i(1600,900)]:
		root.size = resolution
		for i in range(3): await frame()
		var correct = true
		for row in range(5):
			for col in range(9):
				var cell = Vector2i(col,row)
				var point = game.world.project(game.world.cell_position(cell))
				if game.world.cell_from_screen(point) != cell: correct = false
		check(correct, "3D camera picking matches all 45 cells at %dx%d" % [resolution.x,resolution.y])
	await key(KEY_2)
	await click(game.world.project(game.world.cell_position(Vector2i(0,1))))
	check(game.plants.has(Vector2i(0,1)), "real mouse input installs a reactor in the chosen 3D cell")
	var reactor_uid = "bot%d" % game.plants[Vector2i(0,1)].uid
	var actor: OrbitActor3D = game.world.units[reactor_uid]
	check(actor.clips.size() == 5 and actor.player.current_animation == "Deploy", "Blender assembly clip starts on placement")
	actor.player.seek(0.1,true)
	var skeleton: Skeleton3D = actor.find_children("*", "Skeleton3D", true, false)[0]
	var root_bone = skeleton.find_bone("Root")
	var small = skeleton.get_bone_pose_scale(root_bone)
	actor.player.seek(0.9,true)
	check(skeleton.get_bone_pose_scale(root_bone).x > small.x * 2, "deployment animates the actual skeletal transforms")
	for i in range(135): game.advance(0.05)
	await frame()
	check(not game.orbs.is_empty(), "energy appears after the slower first reactor cycle")
	var orb: Dictionary = game.orbs[0]
	var energy_before = game.energy
	await click(game.world.project(game.world.capsule_position(orb)))
	check(game.energy == energy_before + orb.value and game.orbs.is_empty() and not game.world.collecting.is_empty(), "clicking a 3D capsule plays collection and credits energy once")
	await key(KEY_F5)
	await shot("save-slots")
	await button("slot",1)
	check(game.state == "battle" and FileAccess.file_exists(game.store.path), "F5 and slot button manually save the battle")
	game.energy = 0
	await key(KEY_F9)
	await button("slot",1)
	check(game.state == "pause" and game.energy == energy_before + orb.value, "F9 and load button restore the battle paused")
	await shot("pause")
	game.store.data.completed.clear()
	for i in range(1,51): game.store.data.completed[str(i)] = 3
	game.store.data.deck = ["core_pulse","core_reactor","core_shield","seed_01","seed_02","seed_03"]
	for sector in range(5):
		game.start_level(sector*10+1)
		game.wave_wait = 1000
		game.energy = 700
		for row in game.mission.lanes:
			game.selected = "core_reactor"; game.cooldowns[game.selected] = 0
			game.deploy(Vector2i(0,row))
			game.selected = "core_pulse"; game.cooldowns[game.selected] = 0
			game.deploy(Vector2i(3,row))
			game.spawn_enemy(row,"tank",1140)
		for i in range(40): game.advance(0.05)
		await shot("planet-%d" % sector)
	var enemy_uid = "enemy%d" % game.enemies[0].id
	actor = game.world.units[enemy_uid]
	actor.deploy_clock = 0
	actor.tick(0.1,true)
	actor.player.advance(0.1)
	actor.player.seek(0.12,true)
	skeleton = actor.find_children("*", "Skeleton3D", true, false)[0]
	var leg = skeleton.find_bone("Thigh.L")
	var first_pose = skeleton.get_bone_pose_rotation(leg)
	actor.player.seek(0.65,true)
	check(not first_pose.is_equal_approx(skeleton.get_bone_pose_rotation(leg)), "enemy walking changes joint rotations")
	game.enemies[0].hp = 0
	game._update_enemies(0.01)
	await frame()
	check(not game.world.deaths.is_empty() and game.world.deaths[0].player.current_animation == "Death", "destroyed enemies keep a 3D death clip instead of disappearing instantly")
	for language in ["ru","en","de"]:
		game.store.data.language = language
		OrbitLocale.missing.clear()
		game.state = "menu"; await shot("menu-" + language)
		game.state = "map"; await shot("route-" + language)
		game.state = "hangar"; await shot("hangar-" + language)
		game.state = "briefing"; await shot("briefing-" + language)
		game.state = "settings"; await shot("settings-" + language)
		game.open_slots("load"); await shot("load-" + language)
		game.state = "new_confirm"; await frame()
		check(OrbitLocale.missing.is_empty(), "all drawn screens translate into " + language)
		if not OrbitLocale.missing.is_empty(): print(OrbitLocale.missing)
	game.state = "settings"
	await frame()
	await click(Vector2(136 + 535 * 0.27, 406))
	check(absf(game.store.data.music_volume - 0.27) < 0.004 and FileAccess.file_exists(game.store.settings_path), "music slider responds to mouse and writes independent preferences")
	await button("fullscreen")
	check(game.store.data.fullscreen, "fullscreen control enables fullscreen")
	await button("fullscreen")
	check(not game.store.data.fullscreen, "fullscreen control returns to window mode")
	game.state = "pause"
	game.dirty = true
	game.quit_game()
	await frame()
	await button("quit_back")
	check(game.state == "pause" and not game.quitting, "unsaved exit dialog can return to the paused battle")
	game.state = "battle"
	game.effect(game.center(Vector2i(4,2)), Color("ac8dff"), 180)
	game.effects.append({"pos": game.center(Vector2i(4,1)), "radius": 610.0, "life": 0.4, "color": Color("6de6dc"), "beam": true, "uid": game.next_uid()})
	await frame()
	check(game.world.waves_fx.size() == 2, "EMP/blast rings and barrier beams are rendered in 3D")
	print("GRAPHICS3D RESULT: %d checks, %d failures" % [checks,failures])
	for slot in range(1,4):
		for suffix in ["", ".bak", ".tmp"]:
			var path = game.store.slot_path(slot) + suffix
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.store.settings_path + suffix): DirAccess.remove_absolute(game.store.settings_path + suffix)
	game.quit_game(true, 0 if failures == 0 else 1)
