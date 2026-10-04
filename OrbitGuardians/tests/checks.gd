extends SceneTree

var game: OrbitGame
var checks = 0
var failures = 0
var save_path = "user://qa_mechanics.json"

func _initialize() -> void: call_deferred("run")

func check(ok: bool, description: String) -> void:
	checks += 1
	if ok: print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func reset(number: int = 1) -> void:
	game.store.data = OrbitProgress.defaults()
	game.store.data.sound = false
	for i in range(1, number): game.store.data.completed[str(i)] = 3
	game.start_level(number)
	game.wave_wait = 10000.0

func step(seconds: float) -> void:
	for i in range(int(ceil(seconds / 0.025))): game.advance(0.025)

func use_seed(id: String) -> void:
	if id not in game.deck: game.deck.append(id)
	game.selected = id
	game.cooldowns[id] = 0.0
	game.energy = 10000

func run() -> void:
	game = load("res://scenes/Orbit.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.music.stop()
	game.store.path = save_path
	check(game.state == "menu", "project boots into the main menu")
	check(game.catalogue.size() == 53 and game.robots.size() == 53, "three starter seeds and 50 distinct reward seeds exist")
	var types: Dictionary = {}
	for robot in game.catalogue: types[robot.kind] = true
	check(types.size() == 9, "all nine robot classes exist")
	var levels_valid = true
	var bosses = 0
	var signatures: Dictionary = {}
	for n in range(1, 51):
		var mission = OrbitContent.level(n)
		if mission.boss: bosses += 1
		signatures[JSON.stringify(mission)] = true
		if mission.reward != "seed_%02d" % n or mission.waves.is_empty(): levels_valid = false
		for batch in mission.waves:
			for enemy in batch:
				if enemy.row not in mission.lanes: levels_valid = false
	check(levels_valid and signatures.size() == 50 and bosses == 10, "50 distinct missions have valid waves, unique rewards and 10 bosses")
	var first_rows: Dictionary = {}
	for enemy in OrbitContent.level(1).waves[0]: first_rows[enemy.row] = true
	check(first_rows.size() == 3, "first wave covers all three introductory lanes")
	reset()
	check(not game.start_level(2), "locked missions cannot be launched")
	check(game.cell_at(Vector2(240, 292)) == Vector2i(0, 0) and game.cell_at(Vector2(1284, 772)) == Vector2i(-1, -1), "grid boundaries map correctly")
	check(not game.deploy(Vector2i(0, 0)), "inactive lanes reject robots")
	game.selected = "core_reactor"
	check(game.deploy(Vector2i(0, 1)) and game.energy == 250, "reactor costs exactly 50 energy")
	check(not game.deploy(Vector2i(0, 1)) and not game.deploy(Vector2i(1, 1)), "occupied cells and seed cooldown reject deployment")
	step(6.1)
	check(game.orbs.size() == 1, "reactor produces an energy capsule")
	var point: Vector2 = game.orbs[0].pos
	check(game.collect(point) and game.energy == 290 and not game.collect(point), "energy capsule credits once")
	game.selected = "recycle"
	check(game.deploy(Vector2i(0, 1)) and game.energy == 302, "recycling refunds 25 percent, rounded down")
	game.selected = "core_pulse"
	game.energy = 0
	check(not game.deploy(Vector2i(1, 1)), "insufficient energy blocks deployment")
	reset(8)
	check(not game.deploy(game.mission.blocked[0]), "mission debris blocks deployment")
	reset()
	game.selected = "core_pulse"
	game.deploy(Vector2i(0, 1))
	game.spawn_enemy(1, "drone", 520)
	step(12)
	check(game.enemies.is_empty() and game.score == 10, "pulse robot kills a cyborg on its lane")
	reset()
	game.deploy(Vector2i(0, 1))
	game.spawn_enemy(2, "drone", 700)
	step(2)
	check(game.bullets.is_empty() and game.enemies[0].hp == game.enemies[0].max_hp, "weapons do not hit other lanes")
	reset(2)
	use_seed("seed_01")
	game.deploy(Vector2i(0, 1))
	game.spawn_enemy(1, "tank", 460)
	step(2)
	check(game.enemies[0].slow > 0.0, "cryo projectiles slow a cyborg")
	reset(6)
	use_seed("seed_05")
	game.deploy(Vector2i(0, 1))
	game.spawn_enemy(1, "tank", 460)
	game.spawn_enemy(1, "tank", 500)
	step(2.0)
	check(game.enemies[0].hp < game.enemies[0].max_hp and game.enemies[1].hp < game.enemies[1].max_hp, "rail projectile pierces multiple targets")
	var hp: float = game.enemies[0].hp
	step(0.1)
	check(game.enemies[0].hp == hp, "piercing projectile never damages the same target twice")
	reset(5)
	use_seed("seed_04")
	game.deploy(Vector2i(0, 1))
	game.spawn_enemy(1, "tank", 460)
	game.spawn_enemy(2, "tank", 460)
	step(2.0)
	check(game.enemies[0].hp < game.enemies[0].max_hp and game.enemies[1].hp < game.enemies[1].max_hp, "mortar splash hits adjacent lanes")
	reset(4)
	game.selected = "core_shield"
	game.deploy(Vector2i(4, 1))
	use_seed("seed_03")
	game.deploy(Vector2i(3, 1))
	game.plants[Vector2i(4, 1)].hp = 500.0
	step(2.0)
	check(game.plants[Vector2i(4, 1)].hp > 500.0, "repair robot heals an adjacent ally")
	reset(7)
	use_seed("seed_06")
	game.deploy(Vector2i(4, 1))
	game.spawn_enemy(1, "tank", game.center(Vector2i(4, 1)).x + 125)
	step(5.1)
	check(not game.plants.has(Vector2i(4, 1)) and (game.enemies.is_empty() or game.enemies[0].hp < game.enemies[0].max_hp * 0.25), "nova detonates once, consumes itself and heavily damages armored enemies")
	reset(5)
	game.selected = "core_pulse"
	game.deploy(Vector2i(0, 1))
	game.emp_clock = 0.1
	step(0.2)
	check(game.plants[Vector2i(0, 1)].disabled > 0.0, "EMP mission temporarily disables robots")
	step(1.5)
	check(game.plants[Vector2i(0, 1)].disabled == 0.0, "robots recover after EMP")
	reset(12)
	game.deploy(Vector2i(4, 1))
	game.spawn_enemy(1, "disruptor", game.center(Vector2i(4, 1)).x + 140)
	game.enemies[0].special = 0.1
	step(0.2)
	check(game.plants[Vector2i(4, 1)].disabled > 0, "disruptor shuts down nearby defenders")
	reset(22)
	game.spawn_enemy(1, "tank", 850)
	game.enemies[0].hp = 10.0
	game.spawn_enemy(1, "medic", 920)
	game.enemies[1].special = 0.1
	step(0.2)
	check(game.enemies[0].hp > 10.0, "enemy medic restores nearby cyborg armor")
	reset()
	game.spawn_enemy(1, "drone", 200)
	game.spawn_enemy(1, "tank", 900)
	step(0.1)
	check(not game.guards[1] and game.enemies.is_empty() and game.state == "battle", "emergency drone clears its entire lane once")
	game.spawn_enemy(1, "drone", 200)
	step(0.1)
	check(game.state == "defeat", "second breach ends mission")
	reset()
	game.state = "pause"
	var before: float = game.time
	step(3)
	check(game.time == before and not game.deploy(Vector2i(0, 1)), "pause freezes gameplay and deployment")
	reset()
	check(game.energy == 300 and game.guards[1] and game.state == "battle", "retry resets mission resources and defenses")
	game.store.data = OrbitProgress.defaults()
	game.store.data.sound = false
	var earned = true
	for n in range(1, 51):
		earned = game.store.complete(n, 3) and earned
	check(earned and game.store.unlocked().size() == 53 and game.store.next_level() == 50, "all 50 first completions award distinct seeds")
	check(not game.store.complete(50, 2) and game.store.data.completed["50"] == 3 and game.store.unlocked().size() == 53, "replay neither duplicates rewards nor reduces best stars")
	game.toggle_card("seed_25")
	check(game.store.data.deck.size() == 6 and "seed_25" not in game.store.data.deck, "hangar rejects a seventh equipped seed")
	game.toggle_card("core_pulse")
	game.toggle_card("seed_25")
	check(game.store.data.deck.size() == 6 and "seed_25" in game.store.data.deck, "hangar replaces an equipped seed with an unlocked one")
	check(game.store.save_progress(), "campaign is explicitly saved on request")
	game.store.save_progress()
	var restored = OrbitProgress.new()
	restored.path = save_path
	restored.load_progress()
	check(restored.unlocked().size() == 53 and restored.data.deck.size() == 6 and not restored.data.sound, "disk save restores campaign, unlocks, deck and sound setting")
	var f = FileAccess.open(save_path, FileAccess.WRITE)
	f.store_string("{broken")
	f.close()
	restored.load_progress()
	check(restored.data.completed.size() >= 49 and restored.notice != "", "corrupted save recovers from valid backup")
	game.store.save_progress()
	game.store.data = OrbitProgress.defaults()
	game.store.data.deck = ["core_pulse", "core_pulse", "seed_50"]
	game.store.save_progress()
	restored.load_progress()
	check(restored.data.deck == ["core_pulse"], "invalid locked or duplicate deck entries are filtered")
	game.store.data.deck = ["core_pulse"]
	game.toggle_card("core_pulse")
	check(game.store.data.deck == ["core_pulse"], "hangar cannot remove the final seed")
	game.store.data.deck = ["core_reactor"]
	game.state = "briefing"
	game.action("launch")
	check(game.state == "briefing", "mission launch requires a combat robot")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	f = null
	restored = null
	game.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.2).timeout
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix): DirAccess.remove_absolute(save_path + suffix)
	quit(0 if failures == 0 else 1)
