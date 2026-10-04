extends SceneTree
## A deterministic economy-respecting bot completes all 50 actual wave sequences.
var game: OrbitGame
var failures = 0

func _initialize() -> void: call_deferred("run")

func best(kind: String) -> String:
	var id = ""
	var available = game.store.unlocked()
	for robot in game.catalogue:
		if robot.kind == kind and robot.id in available: id = robot.id
	return id

func attempt(id: String, cell: Vector2i) -> bool:
	if id == "" or game.plants.has(cell) or not game.can_use_cell(cell): return false
	game.selected = id
	return game.deploy(cell)

func build() -> void:
	for orb in game.orbs.duplicate(): game.collect(orb.pos)
	var generator = best("reactor")
	var weapon = best("pulse")
	var secondary = best("burst")
	if secondary == "": secondary = weapon
	var rail = best("rail")
	if rail == "": rail = weapon
	var repair = best("repair")
	for row in game.mission.lanes:
		if attempt(generator, Vector2i(0, row)): return
	for row in game.mission.lanes:
		if attempt(weapon, Vector2i(3, row)): return
	for row in game.mission.lanes:
		if attempt(generator, Vector2i(1, row)): return
	for row in game.mission.lanes:
		if attempt(best("shield"), Vector2i(7, row)): return
	for row in game.mission.lanes:
		if attempt(secondary, Vector2i(4, row)): return
	for row in game.mission.lanes:
		if attempt(rail, Vector2i(5, row)): return
	for row in game.mission.lanes:
		if attempt(repair, Vector2i(6, row)): return

func run() -> void:
	game = load("res://scenes/Orbit.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.music.stop()
	game.store.path = "user://qa_campaign.json"
	game.store.data = OrbitProgress.defaults()
	game.store.data.sound = false
	for number in range(1, 51):
		game.store.data.deck = []
		for kind in ["pulse", "reactor", "shield", "burst", "rail", "repair"]:
			var id = best(kind)
			if id != "": game.store.data.deck.append(id)
		if not game.start_level(number):
			failures += 1
			push_error("FAIL: level %d not accessible" % number)
			break
		for tick in range(14400):
			if tick % 5 == 0: build()
			game.advance(0.05)
			if game.state != "battle": break
		if game.state != "victory" or not game.reward_new:
			failures += 1
			push_error("FAIL: mission %d ended %s at %.1fs, wave %d, energy %d" % [number, game.state, game.time, game.wave_index, game.energy])
			break
		print("PASS: mission %02d, %.1fs, %d stars, unlocked %s" % [number, game.time, game.earned_stars, game.mission.reward])
		await process_frame
	if game.store.unlocked().size() != 53:
		failures += 1
		push_error("FAIL: final collection does not contain 53 seeds")
	print("CAMPAIGN RESULT: %d / 50 completed, %d failures" % [game.store.data.completed.size(), failures])
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	for suffix in ["", ".bak", ".tmp"]:
		var path = "user://qa_campaign.json" + suffix
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	quit(0 if failures == 0 else 1)
