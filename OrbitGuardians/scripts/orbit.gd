extends Node2D
class_name OrbitGame

const BOARD = Rect2(240, 292, 1044, 480)
const CELL = Vector2(116, 96)
const COLS = 9
const ROWS = 5

var store = OrbitProgress.new()
var catalogue: Array[Dictionary] = OrbitContent.robots()
var robots: Dictionary = {}
var art: Dictionary = {}
var view: OrbitView
var state = "menu"
var previous_screen = "menu"
var level_page = 0
var collection_page = 0
var focus_robot = "core_pulse"
var mission: Dictionary = OrbitContent.level(1)
var deck: Array = []
var selected = "core_pulse"
var plants: Dictionary = {}
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var orbs: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var guards: Array[bool] = [true, true, true, true, true]
var cooldowns: Dictionary = {}
var energy = 240
var score = 0
var wave_index = 0
var pending: Array = []
var wave_wait = 22.0
var spawn_clock = 0.0
var sky_clock = 10.0
var emp_clock = 25.0
var time = 0.0
var ui_time = 0.0
var serial = 0
var toast = ""
var toast_time = 0.0
var reward_new = false
var earned_stars = 0
var rng = RandomNumberGenerator.new()
var sound_players: Dictionary = {}
var music: AudioStreamPlayer
var world: OrbitWorld
var active_campaign = false
var dirty = false
var return_state = "menu"
var resume_state = ""
var battle_generation = 0
var slot_mode = "save"
var pending_slot = 0
var exit_state = "menu"
var prologue = false
var story_context = "intro"
var story_index = 0
var story_clock = 0.0
var scene_clock = 0.0
var travel_target = 1
var slider_key = ""
var quitting = false

func l(value: String) -> String:
	return OrbitLocale.translate(value, store.data.language)

func _ready() -> void:
	get_tree().auto_accept_quit = false
	get_tree().root.close_requested.connect(quit_game)
	for robot in catalogue: robots[robot.id] = robot
	store.load_settings()
	for key in OrbitContent.TYPES + ["drone", "runner", "tank", "disruptor", "medic", "boss", "ship"]:
		art[key] = load("res://assets3d/icons/%s.png" % key) if ResourceLoader.exists("res://assets3d/icons/%s.png" % key) else load("res://assets/%s.svg" % key)
	for sector in range(5):
		for kind in ["drone", "runner", "tank", "disruptor", "medic", "boss"]:
			var key = "p%d_%s" % [sector, kind]
			art[key] = load("res://assets3d/icons/%s.png" % key) if ResourceLoader.exists("res://assets3d/icons/%s.png" % key) else art[kind]
	for key in ["deploy", "energy", "hit", "alarm", "unlock"]:
		var player = AudioStreamPlayer.new()
		player.stream = load("res://audio/%s.wav" % key)
		player.volume_db = -17.0
		add_child(player)
		sound_players[key] = player
	music = AudioStreamPlayer.new()
	music.stream = load("res://audio/orbit_loop.wav")
	add_child(music)
	music.finished.connect(func():
		if not quitting: music.play()
	)
	apply_settings()
	music.play()
	world = OrbitWorld.new()
	world.game = self
	add_child(world)
	view = OrbitView.new()
	view.game = self
	add_child(view)
	if store.notice != "": notify(store.notice, 8.0)

func fx(key: String) -> void:
	if store.data.sound and sound_players.has(key): sound_players[key].play()

func apply_settings() -> void:
	var master: float = store.data.master_volume if store.data.sound else 0.0
	if music != null: music.volume_db = linear_to_db(maxf(0.00001, master * store.data.music_volume)) - 9.0
	for player in sound_players.values(): player.volume_db = linear_to_db(maxf(0.00001, master * store.data.effects_volume)) - 7.0
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_title(l("Орбитальный рубеж"))
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if store.data.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func begin_story(context: String) -> void:
	story_context = context
	story_index = 0
	story_clock = 0.0
	state = "dialogue"

func story_line() -> Dictionary:
	return OrbitStory.lines(story_context)[story_index]

func advance_story() -> void:
	var message = l(story_line().text)
	if story_clock * 42.0 < message.length():
		story_clock = message.length() / 42.0 + 0.1
		return
	story_index += 1
	story_clock = 0.0
	if story_index < OrbitStory.lines(story_context).size(): return
	match story_context:
		"intro": start_prologue()
		"theft":
			store.data.prologue_seen = true
			dirty = true
			begin_travel(store.next_level())
		"ending":
			store.data.core_recovered = true
			dirty = true
			state = "menu"

func start_prologue() -> void:
	start_level(1)
	prologue = true
	mission = OrbitContent.level(1).duplicate(true)
	mission.number = 0
	mission.name = "Падение станции"
	mission.lanes = [0, 1, 2, 3, 4]
	mission.mode_name = "Эвакуация колонии"
	mission.sector_name = "Станция Астра"
	guards = [false, false, false, false, false]
	energy = 160
	for cell in [Vector2i(2, 1), Vector2i(2, 3)]:
		plants[cell] = {"id": "core_pulse", "hp": 140.0, "timer": 1.6, "flash": 0.0, "disabled": 0.0, "uid": next_uid(), "age": 0.0}
	plants[Vector2i(0, 2)] = {"id": "core_reactor", "hp": 110.0, "timer": 6.0, "flash": 0.0, "disabled": 0.0, "uid": next_uid(), "age": 0.0}
	wave_index = 1
	spawn_clock = 1.0
	notify("Удерживайте шлюз! Гражданские эвакуируются на корабль.", 9.0)

func begin_travel(number: int) -> void:
	travel_target = number
	scene_clock = 0.0
	state = "travel"

func enemy_art(kind: String) -> String:
	if prologue: return kind
	return "p%d_%s" % [mission.sector, kind]

func damage_enemy(enemy: Dictionary, damage: float) -> void:
	var absorbed = minf(enemy.get("shield", 0.0), damage)
	enemy.shield = enemy.get("shield", 0.0) - absorbed
	enemy.hp -= (damage - absorbed) * (0.92 if mission.terrain == "desert" else 1.0)
	enemy.flash = 0.15

func _exit_tree() -> void:
	if music != null:
		music.stop()
		music.stream = null
	for key in sound_players:
		sound_players[key].stop()
		sound_players[key].stream = null

func quit_game(force: bool = false, exit_code: int = 0) -> void:
	if quitting: return
	if active_campaign and dirty and not force:
		if state != "exit_confirm": exit_state = state
		state = "exit_confirm"
		return
	quitting = true
	set_process(false)
	music.stop()
	music.stream = null
	for player in sound_players.values():
		player.stop()
		player.stream = null
	# Let the audio thread release queued WAV playback before engine shutdown.
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(exit_code)

func notify(message: String, duration: float = 3.0) -> void:
	toast = message
	toast_time = duration

func center(cell: Vector2i) -> Vector2:
	return BOARD.position + Vector2(cell) * CELL + CELL * 0.5

func cell_at(point: Vector2) -> Vector2i:
	if not BOARD.has_point(point): return Vector2i(-1, -1)
	return Vector2i((point - BOARD.position) / CELL)

func choose_level(number: int) -> void:
	if not store.accessible(number):
		notify("Сначала завершите предыдущую миссию.")
		return
	if not store.data.prologue_seen:
		begin_story("intro")
		return
	mission = OrbitContent.level(number)
	level_page = int((number - 1) / 10)
	state = "briefing"

func start_level(number: int) -> bool:
	if not store.accessible(number): return false
	active_campaign = true
	resume_state = ""
	dirty = true
	battle_generation += 1
	return_state = "menu"
	prologue = false
	mission = OrbitContent.level(number)
	deck = store.data.deck.duplicate()
	selected = deck[0]
	plants.clear()
	enemies.clear()
	bullets.clear()
	orbs.clear()
	particles.clear()
	effects.clear()
	guards = [true, true, true, true, true]
	cooldowns.clear()
	for id in deck: cooldowns[id] = 0.0
	energy = mission.start_energy
	score = 0
	wave_index = 0
	pending.clear()
	wave_wait = 22.0
	spawn_clock = 0.0
	sky_clock = 10.0
	emp_clock = 25.0
	time = 0.0
	serial = 0
	reward_new = false
	rng.seed = number * 12331
	state = "battle"
	notify("Посадите реакторы, затем стрелков. Собирайте энергию кликом!", 8.0)
	return true

func can_use_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLS and cell.y >= 0 and cell.y < ROWS and cell.y in mission.lanes and cell not in mission.blocked

func deploy(cell: Vector2i) -> bool:
	if state != "battle" or not can_use_cell(cell): return false
	if selected == "recycle":
		if not plants.has(cell): return false
		energy += int(robots[plants[cell].id].cost / 4)
		plants.erase(cell)
		burst(center(cell), Color("6de6dc"))
		fx("deploy")
		return true
	if selected not in deck: return false
	if plants.has(cell):
		notify("Эта клетка занята. Уберите робота инструментом [7].")
		return false
	if cooldowns[selected] > 0.0:
		notify("Семя перезаряжается. Подождите немного.")
		return false
	var stats: Dictionary = robots[selected]
	if energy < stats.cost:
		notify("Не хватает энергии. Соберите синие энергокапсулы.")
		return false
	energy -= stats.cost
	plants[cell] = {"id": selected, "hp": stats.hp, "timer": 6.0 if stats.kind == "reactor" else (5.0 if stats.kind == "nova" else 1.6), "flash": 0.0, "disabled": 0.0, "uid": next_uid(), "age": 0.0}
	cooldowns[selected] = stats.cooldown
	burst(center(cell), Color(stats.color))
	fx("deploy")
	return true

func add_energy(point: Vector2, value: int = 30) -> void:
	orbs.append({"pos": point, "value": value, "age": 0.0, "uid": next_uid()})

func collect(point: Vector2) -> bool:
	if state != "battle": return false
	for i in range(orbs.size() - 1, -1, -1):
		if point.distance_to(orbs[i].pos) < 33.0:
			energy += orbs[i].value
			burst(orbs[i].pos, Color("79ddfb"))
			orbs.remove_at(i)
			fx("energy")
			return true
	return false

func spawn_enemy(row: int, kind: String = "drone", x: float = 1365.0) -> void:
	var stats = OrbitContent.enemy(kind, mission.number)
	serial += 1
	enemies.append({"id": serial, "row": row, "kind": kind, "x": x, "hp": stats.hp, "max_hp": stats.hp, "speed": stats.speed, "bite": stats.bite, "slow": 0.0, "flash": 0.0, "special": 4.0, "biome_clock": 6.0, "shield": stats.hp * 0.12 if mission.terrain == "ice" else 0.0, "biting": false, "age": 0.0})

func burst(point: Vector2, color: Color, count: int = 7) -> void:
	for i in range(count):
		particles.append({"pos": point, "velocity": Vector2(rng.randf_range(-80, 80), rng.randf_range(-100, -15)), "life": 0.5, "color": color})

func effect(point: Vector2, color: Color, radius: float = 70.0) -> void:
	effects.append({"pos": point, "color": color, "radius": radius, "life": 0.4, "uid": next_uid()})

func blast(point: Vector2, damage: float, radius: float) -> void:
	for enemy in enemies:
		var ep = Vector2(enemy.x, center(Vector2i(0, enemy.row)).y)
		if ep.distance_to(point) < radius:
			damage_enemy(enemy, damage)
	effect(point, Color("f4b779"), radius)
	fx("hit")

func _process(delta: float) -> void:
	ui_time += delta
	toast_time = maxf(0.0, toast_time - delta)
	if state == "dialogue": story_clock += delta
	if state in ["cinematic", "travel"]:
		scene_clock += delta
		if state == "cinematic" and scene_clock >= 14.0: begin_story("theft")
		elif state == "travel" and scene_clock >= 4.5: choose_level(travel_target)
	if state == "battle": advance(minf(delta, 0.05))
	view.queue_redraw()

func advance(delta: float) -> void:
	if state != "battle": return
	time += delta
	dirty = true
	for id in cooldowns: cooldowns[id] = maxf(0.0, cooldowns[id] - delta)
	for i in range(particles.size() - 1, -1, -1):
		particles[i].life -= delta
		particles[i].pos += particles[i].velocity * delta
		particles[i].velocity.y += 150.0 * delta
		if particles[i].life <= 0.0: particles.remove_at(i)
	for i in range(effects.size() - 1, -1, -1):
		effects[i].life -= delta
		if effects[i].life <= 0.0: effects.remove_at(i)
	for i in range(orbs.size() - 1, -1, -1):
		orbs[i].age += delta
		if orbs[i].age > 20.0: orbs.remove_at(i)
	sky_clock -= delta
	if sky_clock <= 0.0:
		sky_clock = mission.sky_interval
		var row: int = mission.lanes[rng.randi_range(0, mission.lanes.size() - 1)]
		add_energy(Vector2(rng.randf_range(275, 1220), center(Vector2i(0, row)).y - 20))
	if mission.mode == 4:
		emp_clock -= delta
		if emp_clock <= 0.0:
			emp_clock = 25.0
			for cell in plants: plants[cell].disabled = 1.4
			effect(BOARD.get_center(), Color("ba8cf4"), 620)
			notify("ЭМИ-импульс! Роботы восстановятся через 1,4 секунды.")
	_update_waves(delta)
	if state != "battle": return
	_update_robots(delta)
	_update_bullets(delta)
	_update_enemies(delta)

func _update_waves(delta: float) -> void:
	if prologue:
		if time >= 32.0:
			finish(false)
			return
		spawn_clock -= delta
		if spawn_clock <= 0.0:
			spawn_clock = 1.5
			spawn_enemy(int(time / 1.5) % 5, "boss" if time > 13.0 else "tank", 1210.0)
			enemies.back().hp *= 5.0
			enemies.back().max_hp = enemies.back().hp
			enemies.back().speed = 45.0
		return
	if not pending.is_empty():
		spawn_clock -= delta
		if spawn_clock <= 0.0:
			var event: Dictionary = pending.pop_front()
			spawn_enemy(event.row, event.kind)
			spawn_clock = mission.spawn_interval
	elif enemies.is_empty():
		if wave_index >= mission.waves.size():
			finish(true)
			return
		wave_wait -= delta
		if wave_wait <= 0.0:
			pending = mission.waves[wave_index].duplicate(true)
			wave_index += 1
			wave_wait = 12.0
			spawn_clock = 0.0
			notify("Волна %d / %d. Киборги приближаются!" % [wave_index, mission.waves.size()])
			fx("alarm")

func _update_robots(delta: float) -> void:
	for cell in plants.keys():
		var bot: Dictionary = plants[cell]
		var stats: Dictionary = robots[bot.id]
		bot.age = bot.get("age", 0.0) + delta
		bot.flash = maxf(0.0, bot.flash - delta)
		if bot.disabled > 0:
			bot.disabled = maxf(0.0, bot.disabled - delta)
			continue
		bot.timer -= delta
		if bot.timer > 0: continue
		match stats.kind:
			"reactor":
				add_energy(center(cell) + Vector2(17, -22), stats.energy)
				bot.timer = stats.interval
			"shield": pass
			"repair":
				for neighbour in plants:
					if neighbour != cell and absi(neighbour.x - cell.x) + absi(neighbour.y - cell.y) == 1:
						var target: Dictionary = plants[neighbour]
						target.hp = minf(robots[target.id].hp, target.hp + 24.0 + stats.tier * 5)
						target.flash = 0.2
				bot.timer = stats.interval
				bot.flash = 0.12
			"nova":
				blast(center(cell), stats.damage, 220.0)
				plants.erase(cell)
			_:
				for enemy in enemies:
					if enemy.row == cell.y and enemy.hp > 0 and enemy.x > center(cell).x:
						var count = 2 if stats.kind == "burst" else 1
						for i in range(count):
							bullets.append({"pos": center(cell) + Vector2(31 - i * 23, -4), "row": cell.y, "damage": stats.damage, "kind": stats.kind, "hits": [], "uid": next_uid()})
						bot.timer = stats.interval
						bot.flash = 0.1
						break

func _update_bullets(delta: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		var bullet: Dictionary = bullets[i]
		var old_x: float = bullet.pos.x
		bullet.pos.x += (580.0 if bullet.kind == "rail" else 370.0) * delta
		var candidates: Array[Dictionary] = []
		for enemy in enemies:
			if enemy.row == bullet.row and enemy.hp > 0 and enemy.id not in bullet.hits and enemy.x >= old_x - 28 and enemy.x <= bullet.pos.x + 28:
				candidates.append(enemy)
		candidates.sort_custom(func(a, b): return a.x < b.x)
		var consumed = false
		for target in candidates:
			bullet.hits.append(target.id)
			if bullet.kind == "mortar":
				blast(Vector2(target.x, center(Vector2i(0, target.row)).y), bullet.damage, 145.0)
			else:
				damage_enemy(target, bullet.damage)
				if bullet.kind == "cryo": target.slow = 3.0
				burst(Vector2(target.x, bullet.pos.y), Color("6de6dc"), 3)
				fx("hit")
			if bullet.kind != "rail":
				consumed = true
				break
		if consumed or bullet.pos.x > 1470.0: bullets.remove_at(i)

func _update_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[i]
		if enemy.hp <= 0:
			burst(Vector2(enemy.x, center(Vector2i(0, enemy.row)).y), Color("ec897b"))
			score += 100 if enemy.kind == "boss" else 10
			enemies.remove_at(i)
			continue
		enemy.age = enemy.get("age", 0.0) + delta
		enemy.flash = maxf(0.0, enemy.flash - delta)
		enemy.slow = maxf(0.0, enemy.slow - delta)
		enemy.special -= delta
		enemy.biome_clock -= delta
		if enemy.biome_clock <= 0:
			enemy.biome_clock = 6.0
			if mission.terrain == "forest": enemy.hp = minf(enemy.max_hp, enemy.hp + enemy.max_hp * 0.025)
			elif mission.terrain == "void" and enemy.kind == "runner":
				enemy.row = (enemy.row + 1) % 5
				effect(Vector2(enemy.x, center(Vector2i(0, enemy.row)).y), Color("c89bf1"), 42)
		if enemy.special <= 0:
			enemy.special = 8.0 if enemy.kind == "disruptor" else 4.0
			if enemy.kind == "disruptor":
				for cell in plants:
					if center(cell).distance_to(Vector2(enemy.x, center(Vector2i(0, enemy.row)).y)) < 185:
						plants[cell].disabled = 1.7
					effect(Vector2(enemy.x, center(Vector2i(0, enemy.row)).y), Color("ba8cf4"), 185)
			elif enemy.kind == "medic":
				for other in enemies:
					if other.id != enemy.id and other.row == enemy.row and absf(other.x - enemy.x) < 170 and other.hp > 0:
						other.hp = minf(other.max_hp, other.hp + 10.0)
		enemy.biting = false
		var target = Vector2i(-1, -1)
		var rightmost = -INF
		for cell in plants:
			var px: float = center(cell).x
			if cell.y == enemy.row and enemy.x <= px + 48 and enemy.x >= px - 32 and px > rightmost:
				target = cell
				rightmost = px
		if target.x >= 0:
			enemy.biting = true
			plants[target].hp -= enemy.bite * delta
			if plants[target].hp <= 0:
				burst(center(target), Color("6f8ba1"))
				plants.erase(target)
		else:
			enemy.x -= enemy.speed * (0.45 if enemy.slow > 0 else 1.0) * (1.15 if mission.terrain == "lava" and enemy.hp < enemy.max_hp * 0.5 else 1.0) * delta
		if enemy.x < BOARD.position.x - 37:
			if guards[enemy.row]:
				guards[enemy.row] = false
				for other in enemies:
					if other.row == enemy.row: other.hp = 0.0
				effects.append({"pos": Vector2(720, center(Vector2i(0, enemy.row)).y), "radius": 610.0, "life": 0.4, "color": Color("6de6dc"), "beam": true, "uid": next_uid()})
				fx("alarm")
				notify("Аварийный барьер очистил дорожку %d. Второй прорыв опасен!" % (enemy.row + 1))
			else:
				finish(false)
				return

func finish(won: bool) -> void:
	if state != "battle": return
	if prologue:
		prologue = false
		state = "cinematic"
		scene_clock = 0.0
		toast_time = 0.0
		fx("alarm")
		return
	dirty = true
	state = "victory" if won else "defeat"
	if won:
		var used = 0
		for row in mission.lanes:
			if not guards[row]: used += 1
		earned_stars = 3 if used == 0 else (2 if used <= 2 else 1)
		reward_new = store.complete(mission.number, earned_stars)
		fx("unlock")
		if store.notice != "": notify(store.notice, 8)
	else:
		fx("alarm")

func toggle_card(id: String) -> void:
	if id not in store.unlocked():
		notify("Это семя откроется после миссии %d." % robots[id].unlock)
		return
	if id in store.data.deck:
		if store.data.deck.size() == 1:
			notify("В наборе должен оставаться хотя бы один робот.")
			return
		store.data.deck.erase(id)
	elif store.data.deck.size() >= 6:
		notify("В наборе 6 семян. Сначала снимите одно нажатием на карточку.")
		return
	else:
		store.data.deck.append(id)
	dirty = true

func _unhandled_input(event: InputEvent) -> void:
	if quitting: return
	if event is InputEventMouseMotion and slider_key != "":
		update_slider(get_local_mouse_position())
		return
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and slider_key != "":
		slider_key = ""
		store.save_settings()
		fx("deploy")
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5 and active_campaign:
			open_slots("save")
			return
		if event.keycode == KEY_F9:
			open_slots("load")
			return
		if state == "dialogue" and event.keycode in [KEY_ENTER, KEY_SPACE]:
			advance_story()
			return
		if state == "travel" and event.keycode in [KEY_ENTER, KEY_SPACE]:
			choose_level(travel_target)
			return
		if state == "battle":
			if event.keycode >= KEY_1 and event.keycode <= KEY_6:
				var index = event.keycode - KEY_1
				if index < deck.size(): selected = deck[index]
			elif event.keycode == KEY_7: selected = "recycle"
			elif event.keycode in [KEY_ESCAPE, KEY_SPACE]: state = "pause"
		elif state == "pause" and event.keycode in [KEY_ESCAPE, KEY_SPACE, KEY_ENTER]: state = "battle"
		elif event.keycode == KEY_ESCAPE:
			if state == "exit_confirm": state = exit_state
			elif state in ["save", "load", "new_confirm"]: state = return_state
			elif state == "settings": state = previous_screen
			elif state not in ["dialogue", "cinematic", "travel"]: state = "menu"
		elif event.keycode == KEY_ENTER:
			if state == "menu": action("continue" if active_campaign else "new_game")
			elif state == "briefing": action("launch")
			elif state == "victory": action("next")
			elif state == "defeat": action("retry")
		if event.keycode == KEY_M: action("sound")
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT and state == "battle":
			selected = "recycle"
			return
		if event.button_index != MOUSE_BUTTON_LEFT: return
		var point = get_local_mouse_position()
		for button in view.buttons:
			if button.rect.has_point(point):
				if not button.get("disabled", false): action(button.action, button.get("value", ""))
				return
		if state == "dialogue": advance_story()
		elif state == "battle" and not world.collect_screen(point): deploy(world.cell_from_screen(point))

func update_slider(point: Vector2) -> void:
	store.data[slider_key] = clampf((point.x - 136.0) / 535.0, 0.0, 1.0)
	apply_settings()

func action(command: String, value: Variant = "") -> void:
	match command:
		"continue":
			if not active_campaign: return
			if resume_state != "":
				state = "pause" if resume_state == "battle" else resume_state
				resume_state = ""
			elif not store.data.prologue_seen: begin_story("intro")
			else: begin_travel(store.next_level())
		"new_game":
			return_state = state
			if active_campaign: state = "new_confirm"
			else: new_game()
		"new_accept": new_game()
		"save", "load": open_slots(command)
		"slot":
			if slot_mode == "save":
				if not store.slot_info(int(value)).is_empty(): pending_slot = int(value)
				else: save_slot(int(value))
			else: load_slot(int(value))
		"overwrite": save_slot(pending_slot)
		"cancel_overwrite": pending_slot = 0
		"slot_back":
			pending_slot = 0
			state = return_state
		"legacy": load_legacy()
		"story": action("new_game")
		"journey":
			if not store.data.prologue_seen: begin_story("intro")
			else: begin_travel(store.next_level())
		"dialogue_next": advance_story()
		"travel_skip": choose_level(travel_target)
		"language":
			if str(value) in ["ru", "en", "de"]:
				store.data.language = str(value)
				store.save_settings()
				apply_settings()
		"fullscreen":
			store.data.fullscreen = not store.data.fullscreen
			store.save_settings()
			apply_settings()
		"slider":
			slider_key = str(value)
			update_slider(get_local_mouse_position())
		"quit": quit_game()
		"quit_accept": quit_game(true)
		"quit_back": state = exit_state
		"menu":
			var underlying = return_state if state in ["save", "load"] else (previous_screen if state == "settings" else state)
			if underlying != "menu": resume_state = "pause" if underlying == "battle" else underlying
			return_state = "menu"
			state = "menu"
		"map":
			if not active_campaign: return
			level_page = int((store.next_level() - 1) / 10)
			state = "map"
		"level": choose_level(int(value))
		"planet": level_page = clampi(int(value), 0, 4)
		"map_page": level_page = clampi(level_page + int(value), 0, 4)
		"hangar":
			if not active_campaign: return
			previous_screen = state if state in ["briefing", "menu", "map"] else "menu"
			state = "hangar"
		"hangar_back": state = previous_screen
		"collection_page": collection_page = clampi(collection_page + int(value), 0, 4)
		"inspect": focus_robot = str(value)
		"equip": toggle_card(str(value))
		"launch":
			var has_weapon = false
			for id in store.data.deck:
				if robots[id].damage > 0: has_weapon = true
			if not has_weapon:
				notify("Выберите хотя бы одного боевого робота в ангаре.")
				return
			start_level(mission.number)
		"select": selected = str(value)
		"pause": state = "pause"
		"resume": state = "battle"
		"retry":
			if prologue: start_prologue()
			else: start_level(mission.number)
		"next":
			if mission.number >= 50: begin_story("ending")
			else: begin_travel(mission.number + 1)
		"settings":
			previous_screen = "pause" if state == "battle" else state
			state = "settings"
		"settings_back": state = previous_screen
		"sound":
			store.data.sound = not store.data.sound
			store.save_settings()
			apply_settings()


func next_uid() -> int:
	serial += 1
	return serial

func new_game() -> void:
	store.new_campaign()
	active_campaign = true
	dirty = true
	resume_state = ""
	return_state = "menu"
	plants.clear()
	enemies.clear()
	orbs.clear()
	bullets.clear()
	mission = OrbitContent.level(1)
	prologue = false
	deck = store.data.deck.duplicate()
	selected = deck[0]
	pending.clear()
	cooldowns.clear()
	guards = [true, true, true, true, true]
	energy = mission.start_energy
	score = 0
	time = 0
	serial = 0
	wave_index = 0
	reward_new = false
	earned_stars = 0
	level_page = 0
	focus_robot = "core_pulse"
	begin_story("intro")

func open_slots(mode: String) -> void:
	if mode == "save" and not active_campaign: return
	if state not in ["save", "load", "new_confirm"]: return_state = state
	pending_slot = 0
	slot_mode = mode
	state = mode

static func encode(value: Variant) -> Variant:
	if value is Vector2: return {"v2": [value.x, value.y]}
	if value is Vector2i: return {"v2i": [value.x, value.y]}
	if value is Array:
		var result = []
		for item in value: result.append(encode(item))
		return result
	if value is Dictionary:
		var result = {}
		for key in value: result[str(key)] = encode(value[key])
		return result
	return value

static func decode(value: Variant) -> Variant:
	if value is Dictionary:
		if value.size() == 1 and value.get("v2") is Array and value.v2.size() == 2: return Vector2(float(value.v2[0]), float(value.v2[1]))
		if value.size() == 1 and value.get("v2i") is Array and value.v2i.size() == 2: return Vector2i(int(value.v2i[0]), int(value.v2i[1]))
		var result = {}
		for key in value: result[key] = decode(value[key])
		return result
	if value is Array:
		var result = []
		for item in value: result.append(decode(item))
		return result
	return value

const SESSION_FIELDS = ["selected", "energy", "score", "wave_index", "wave_wait", "spawn_clock", "sky_clock", "emp_clock", "time", "serial", "prologue", "story_context", "story_index", "story_clock", "scene_clock", "travel_target", "reward_new", "earned_stars"]

func snapshot() -> Dictionary:
	var target = return_state if state in ["save", "load", "new_confirm"] else state
	if target == "exit_confirm": target = exit_state
	if target == "settings": target = previous_screen
	if target == "menu" and resume_state != "": target = resume_state
	var result = {"state": target, "mission_number": mission.number, "rng_state": str(rng.state), "deck": deck.duplicate(), "guards": guards.duplicate(), "cooldowns": cooldowns.duplicate(), "enemies": encode(enemies), "bullets": encode(bullets), "orbs": encode(orbs), "pending": encode(pending), "plants": []}
	for field in SESSION_FIELDS: result[field] = get(field)
	for cell in plants: result.plants.append({"cell": [cell.x, cell.y], "bot": plants[cell].duplicate(true)})
	return result

func save_slot(slot: int) -> bool:
	if not active_campaign or slot < 1 or slot > 3: return false
	var ok = store.save_slot(slot, snapshot())
	if ok:
		dirty = false
		pending_slot = 0
		state = return_state
		notify("Сохранение записано. Бой и маршрут сохранены.", 5)
	else: notify(store.notice, 8)
	return ok

func valid_session(payload: Dictionary, progress: Dictionary) -> bool:
	var states = ["menu", "map", "hangar", "briefing", "battle", "pause", "victory", "defeat", "dialogue", "cinematic", "travel", "settings"]
	if payload.get("state") not in states: return false
	var number = int(payload.get("mission_number", -1))
	if number < 0 or number > 50: return false
	for key in SESSION_FIELDS:
		if not payload.has(key): return false
	for key in ["energy", "score", "wave_index", "wave_wait", "spawn_clock", "sky_clock", "emp_clock", "time", "serial", "story_index", "story_clock", "scene_clock", "travel_target", "earned_stars"]:
		if not numeric(payload[key]): return false
	for key in ["prologue", "reward_new"]:
		if not payload[key] is bool: return false
	if not payload.selected is String or (payload.selected != "recycle" and not robots.has(payload.selected)): return false
	if payload.story_context not in ["intro", "theft", "ending"]: return false
	if payload.energy < 0 or payload.time < 0 or payload.serial < 0 or payload.earned_stars < 0 or payload.earned_stars > 3: return false
	if payload.travel_target < 1 or payload.travel_target > 50: return false
	if payload.state == "dialogue" and (payload.story_index < 0 or payload.story_index >= OrbitStory.lines(payload.story_context).size()): return false
	if payload.wave_index < 0 or payload.wave_index > OrbitContent.level(maxi(1,number)).waves.size(): return false

	for key in ["deck", "guards", "enemies", "bullets", "orbs", "pending", "plants"]:
		if not payload.get(key) is Array: return false
	if payload.guards.size() != 5 or payload.plants.size() > 45 or payload.enemies.size() > 500 or payload.orbs.size() > 500 or payload.bullets.size() > 1000: return false
	if not payload.get("cooldowns") is Dictionary or not str(payload.get("rng_state", "")).is_valid_int(): return false
	var owned = OrbitContent.STARTERS.duplicate()
	for key in progress.completed: owned.append("seed_%02d" % int(key))
	if payload.deck.size() > 6: return false
	for guard in payload.guards:
		if not guard is bool: return false
	for key in payload.cooldowns:
		if not robots.has(key) or not numeric(payload.cooldowns[key]) or payload.cooldowns[key] < 0: return false
	for event in payload.pending:
		if not event is Dictionary or event.get("kind") not in ["drone", "runner", "tank", "disruptor", "medic", "boss"] or not numeric(event.get("row")): return false
		if event.row < 0 or event.row > 4: return false
	for id in payload.deck:
		if id not in owned: return false
	var used = {}
	for entry in payload.plants:
		if not entry is Dictionary or not entry.get("cell") is Array or entry.cell.size() != 2 or not entry.get("bot") is Dictionary: return false
		var cell = Vector2i(int(entry.cell[0]), int(entry.cell[1]))
		if cell.x < 0 or cell.x >= 9 or cell.y < 0 or cell.y >= 5 or used.has(cell): return false
		used[cell] = true
		if entry.bot.get("id") not in owned: return false
		for key in ["uid", "hp", "timer", "disabled", "flash", "age"]:
			if not numeric(entry.bot.get(key)): return false
	for enemy in payload.enemies:
		if not enemy is Dictionary or enemy.get("kind") not in ["drone", "runner", "tank", "disruptor", "medic", "boss"]: return false
		if int(enemy.get("row", -1)) < 0 or int(enemy.get("row", -1)) >= 5: return false
		for key in ["id", "x", "hp", "max_hp", "speed", "bite", "slow", "flash", "special", "biome_clock", "shield"]:
			if not numeric(enemy.get(key)): return false
	for orb in payload.orbs:
		if not orb is Dictionary or not safe_vector(orb.get("pos")) or not numeric(orb.get("value")) or not numeric(orb.get("uid")) or not numeric(orb.get("age")): return false
	for bullet in payload.bullets:
		if not bullet is Dictionary or not safe_vector(bullet.get("pos")) or not bullet.get("hits") is Array or not numeric(bullet.get("uid")) or not numeric(bullet.get("damage")) or not numeric(bullet.get("row")) or bullet.get("kind") not in OrbitContent.TYPES: return false
	return true

func load_slot(slot: int) -> bool:
	var payload = store.load_slot(slot)
	if payload.is_empty() or not valid_session(payload.session, payload.progress):
		notify("Не удалось загрузить сохранение. Файл сохранён без изменений.", 7)
		return false
	store.adopt(payload.progress)
	var session: Dictionary = payload.session
	mission = OrbitContent.level(maxi(1, int(session.mission_number)))
	for field in SESSION_FIELDS: set(field, session[field])
	if prologue:
		mission.number = 0
		mission.name = "Падение станции"
		mission.lanes = [0, 1, 2, 3, 4]
		mission.sector_name = "Станция Астра"
		mission.mode_name = "Эвакуация колонии"
	plants.clear()
	for entry in session.plants: plants[Vector2i(int(entry.cell[0]), int(entry.cell[1]))] = entry.bot.duplicate(true)
	enemies.assign(decode(session.enemies))
	bullets.assign(decode(session.bullets))
	orbs.assign(decode(session.orbs))
	pending = decode(session.pending)
	deck = session.deck.duplicate()
	guards.assign(session.guards)
	cooldowns = session.cooldowns.duplicate()
	rng.state = int(session.rng_state)
	particles.clear()
	effects.clear()
	battle_generation += 1
	active_campaign = true
	dirty = false
	return_state = "menu"
	resume_state = ""
	pending_slot = 0
	state = "pause" if session.state in ["battle", "pause"] else session.state
	if state == "settings": state = "menu"
	level_page = int((store.next_level() - 1) / 10)
	apply_settings()
	notify("Сохранение загружено. Нажмите «Продолжить», когда будете готовы.", 6)
	return true

func load_legacy() -> bool:
	var parsed = store.read_json("user://orbit_progress.json")
	if not store.valid(parsed): return false
	store.adopt(parsed)
	active_campaign = true
	dirty = true
	resume_state = ""
	return_state = "menu"
	state = "map"
	level_page = int((store.next_level() - 1) / 10)
	notify("Старая кампания импортирована. Сохраните её в новый слот.", 7)
	return true


static func numeric(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func safe_vector(value: Variant) -> bool:
	return value is Dictionary and value.get("v2") is Array and value.v2.size() == 2 and numeric(value.v2[0]) and numeric(value.v2[1])
