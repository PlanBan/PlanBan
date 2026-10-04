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
var wave_wait = 15.0
var spawn_clock = 0.0
var sky_clock = 2.0
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

func _ready() -> void:
	for robot in catalogue: robots[robot.id] = robot
	store.load_progress()
	for key in OrbitContent.TYPES + ["drone", "runner", "tank", "disruptor", "medic", "boss", "guard"]:
		art[key] = load("res://assets/%s.svg" % key)
	for key in ["deploy", "energy", "hit", "alarm", "unlock"]:
		var player = AudioStreamPlayer.new()
		player.stream = load("res://audio/%s.wav" % key)
		player.volume_db = -17.0
		add_child(player)
		sound_players[key] = player
	music = AudioStreamPlayer.new()
	music.stream = load("res://audio/orbit_loop.wav")
	music.volume_db = -23.0
	add_child(music)
	music.finished.connect(func():
		if store.data.sound: music.play()
	)
	if store.data.sound: music.play()
	view = OrbitView.new()
	view.game = self
	add_child(view)
	if store.notice != "": notify(store.notice, 8.0)

func fx(key: String) -> void:
	if store.data.sound and sound_players.has(key): sound_players[key].play()

func _exit_tree() -> void:
	if music != null:
		music.stop()
		music.stream = null
	for key in sound_players:
		sound_players[key].stop()
		sound_players[key].stream = null

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
	mission = OrbitContent.level(number)
	state = "briefing"

func start_level(number: int) -> bool:
	if not store.accessible(number): return false
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
	wave_wait = 15.0
	spawn_clock = 0.0
	sky_clock = 2.0
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
	plants[cell] = {"id": selected, "hp": stats.hp, "timer": 1.0 if stats.kind == "reactor" else (5.0 if stats.kind == "nova" else 0.2), "flash": 0.0, "disabled": 0.0}
	cooldowns[selected] = stats.cooldown
	burst(center(cell), Color(stats.color))
	fx("deploy")
	return true

func add_energy(point: Vector2, value: int = 30) -> void:
	orbs.append({"pos": point, "value": value, "age": 0.0})

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
	enemies.append({"id": serial, "row": row, "kind": kind, "x": x, "hp": stats.hp, "max_hp": stats.hp, "speed": stats.speed, "bite": stats.bite, "slow": 0.0, "flash": 0.0, "special": 4.0, "biting": false})

func burst(point: Vector2, color: Color, count: int = 7) -> void:
	for i in range(count):
		particles.append({"pos": point, "velocity": Vector2(rng.randf_range(-80, 80), rng.randf_range(-100, -15)), "life": 0.5, "color": color})

func effect(point: Vector2, color: Color, radius: float = 70.0) -> void:
	effects.append({"pos": point, "color": color, "radius": radius, "life": 0.4})

func blast(point: Vector2, damage: float, radius: float) -> void:
	for enemy in enemies:
		var ep = Vector2(enemy.x, center(Vector2i(0, enemy.row)).y)
		if ep.distance_to(point) < radius:
			enemy.hp -= damage
			enemy.flash = 0.15
	effect(point, Color("f4b779"), radius)
	fx("hit")

func _process(delta: float) -> void:
	ui_time += delta
	toast_time = maxf(0.0, toast_time - delta)
	if state == "battle": advance(minf(delta, 0.05))
	view.queue_redraw()

func advance(delta: float) -> void:
	if state != "battle": return
	time += delta
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
		if orbs[i].age > 15.0: orbs.remove_at(i)
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
			wave_wait = 7.0
			spawn_clock = 0.0
			notify("Волна %d / %d. Киборги приближаются!" % [wave_index, mission.waves.size()])
			fx("alarm")

func _update_robots(delta: float) -> void:
	for cell in plants.keys():
		var bot: Dictionary = plants[cell]
		var stats: Dictionary = robots[bot.id]
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
							bullets.append({"pos": center(cell) + Vector2(31 - i * 23, -4), "row": cell.y, "damage": stats.damage, "kind": stats.kind, "hits": []})
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
				target.hp -= bullet.damage
				target.flash = 0.12
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
		enemy.flash = maxf(0.0, enemy.flash - delta)
		enemy.slow = maxf(0.0, enemy.slow - delta)
		enemy.special -= delta
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
			enemy.x -= enemy.speed * (0.45 if enemy.slow > 0 else 1.0) * delta
		if enemy.x < BOARD.position.x - 37:
			if guards[enemy.row]:
				guards[enemy.row] = false
				for other in enemies:
					if other.row == enemy.row: other.hp = 0.0
				effects.append({"pos": Vector2(720, center(Vector2i(0, enemy.row)).y), "radius": 610.0, "life": 0.4, "color": Color("6de6dc"), "beam": true})
				fx("alarm")
				notify("Аварийный дрон очистил дорожку %d. Второй прорыв опасен!" % (enemy.row + 1))
			else:
				finish(false)
				return

func finish(won: bool) -> void:
	if state != "battle": return
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
	store.save_progress()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if state == "battle":
			if event.keycode >= KEY_1 and event.keycode <= KEY_6:
				var index = event.keycode - KEY_1
				if index < deck.size(): selected = deck[index]
			elif event.keycode == KEY_7: selected = "recycle"
			elif event.keycode in [KEY_ESCAPE, KEY_SPACE]: state = "pause"
		elif state == "pause" and event.keycode in [KEY_ESCAPE, KEY_SPACE, KEY_ENTER]: state = "battle"
		elif event.keycode == KEY_ESCAPE:
			state = "menu"
		elif event.keycode == KEY_ENTER:
			if state == "menu": choose_level(store.next_level())
			elif state == "briefing": action("launch")
			elif state == "victory": action("next")
			elif state == "defeat": start_level(mission.number)
		if event.keycode == KEY_M: action("sound")
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT and state == "battle":
			selected = "recycle"
			return
		if event.button_index != MOUSE_BUTTON_LEFT: return
		var point = get_global_mouse_position()
		for button in view.buttons:
			if button.rect.has_point(point):
				if not button.get("disabled", false): action(button.action, button.get("value", ""))
				return
		if state == "battle" and not collect(point): deploy(cell_at(point))

func action(command: String, value: Variant = "") -> void:
	match command:
		"continue": choose_level(store.next_level())
		"menu": state = "menu"
		"map":
			level_page = int((store.next_level() - 1) / 10)
			state = "map"
		"level": choose_level(int(value))
		"map_page": level_page = clampi(level_page + int(value), 0, 4)
		"hangar":
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
		"retry": start_level(mission.number)
		"next":
			if mission.number >= 50: state = "menu"
			else: choose_level(mission.number + 1)
		"settings": state = "settings"
		"sound":
			store.data.sound = not store.data.sound
			store.save_progress()
			if store.data.sound: music.play()
			else: music.stop()
