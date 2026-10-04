extends Node2D
class_name OrbitView

const INK = Color("e7f4fa")
const MUTED = Color("8faabd")
const CYAN = Color("6de6dc")
const PANEL = Color("112637")
const LINE = Color("29465b")
var game: OrbitGame
var font: Font
var buttons: Array[Dictionary] = []
var stars: Array[Vector3] = []

func _ready() -> void:
	font = ThemeDB.fallback_font
	var random = RandomNumberGenerator.new()
	random.seed = 4371
	for i in range(145): stars.append(Vector3(random.randf_range(0, 1440), random.randf_range(0, 900), random.randf_range(0.6, 1.8)))

func text(value: String, point: Vector2, size: int = 20, color: Color = INK) -> void:
	draw_string(font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func centered(value: String, rect: Rect2, size: int = 20, color: Color = INK) -> void:
	var width = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	text(value, Vector2(rect.get_center().x - width / 2, rect.get_center().y + size * 0.35), size, color)

func paragraph(value: String, point: Vector2, width: float, size: int = 18, color: Color = MUTED, spacing: float = 27.0) -> void:
	var line = ""
	var y: float = point.y
	for word in value.split(" "):
		var candidate = word if line == "" else line + " " + word
		if line != "" and font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
			text(line, Vector2(point.x, y), size, color)
			y += spacing
			line = word
		else: line = candidate
	if line != "": text(line, Vector2(point.x, y), size, color)

func panel(rect: Rect2, color: Color = PANEL, radius: int = 16, border: Color = LINE, border_width: int = 1) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	draw_style_box(style, rect)

func button(title: String, rect: Rect2, command: String, value: Variant = "", primary: bool = false, disabled: bool = false, size: int = 19) -> void:
	var hover = rect.has_point(get_global_mouse_position()) and not disabled
	var color = Color("397b83") if primary else Color("1a3547")
	if hover: color = color.lightened(0.16)
	if disabled: color = Color("132431")
	panel(rect, color, 12, CYAN if primary else LINE, 1)
	centered(title, rect, size, MUTED if disabled else INK)
	buttons.append({"rect": rect, "action": command, "value": value, "disabled": disabled})

func icon(kind: String, point: Vector2, size: Vector2, color: Color = Color.WHITE) -> void:
	draw_texture_rect(game.art[kind], Rect2(point - size / 2, size), false, color)

func star(point: Vector2, radius: float, color: Color) -> void:
	var points = PackedVector2Array()
	for i in range(10):
		points.append(point + Vector2.from_angle(-PI / 2 + i * TAU / 10) * (radius if i % 2 == 0 else radius * 0.45))
	draw_colored_polygon(points, color)

func energy_icon(point: Vector2, radius: float, alpha: float = 1.0) -> void:
	draw_circle(point, radius + 8, Color(0.3, 0.9, 1.0, alpha * 0.13))
	draw_circle(point, radius, Color(0.24, 0.63, 0.79, alpha))
	draw_arc(point, radius, game.ui_time, game.ui_time + TAU * 0.8, 24, Color(0.46, 0.88, 0.98, alpha), 2)
	var bolt = PackedVector2Array([point + Vector2(4, -radius * 0.65), point + Vector2(-radius * 0.5, 2), point + Vector2(0, 2), point + Vector2(-3, radius * 0.65), point + Vector2(radius * 0.5, -3), point + Vector2(2, -3)])
	draw_colored_polygon(bolt, Color(0.85, 1.0, 1.0, alpha))

func background() -> void:
	draw_rect(Rect2(0, 0, 1440, 900), Color("081321"))
	for i in range(12):
		draw_circle(Vector2(1120, 160), 560 - i * 33, Color(0.08, 0.18, 0.29, 0.045))
	for point in stars:
		var alpha = 0.35 + 0.25 * sin(game.ui_time * 0.45 + point.x)
		draw_circle(Vector2(point.x, point.y), point.z, Color(0.74, 0.89, 1, alpha))
	var sector: int = game.level_page if game.state == "map" else game.mission.sector
	var color = Color(OrbitContent.COLORS[sector])
	var pos = Vector2(1114, 352)
	var radius = 230.0
	draw_circle(pos, radius + 13, Color(color.r, color.g, color.b, 0.055))
	draw_circle(pos, radius + 5, Color(color.r, color.g, color.b, 0.12))
	draw_set_transform(pos, -0.28, Vector2(1, 0.30))
	draw_arc(Vector2.ZERO, radius * 1.48, 0, TAU, 120, Color(color.r, color.g, color.b, 0.18), 19)
	draw_set_transform(Vector2.ZERO)
	draw_circle(pos, radius, color.darkened(0.63))
	for i in range(19):
		var t = float(i) / 19
		draw_circle(pos + Vector2(-i * 2.6, -i * 2.0), radius - i * 8, color.darkened(0.56 - t * 0.35))
	draw_arc(pos + Vector2(-36, -36), 136, 3.5, 5.2, 60, Color(color.r, color.g, color.b, 0.15), 28)
	draw_arc(pos + Vector2(-16, -20), 182, 0.35, 1.5, 60, Color(0.1, 0.17, 0.24, 0.2), 17)
	draw_set_transform(pos, -0.28, Vector2(1, 0.30))
	draw_arc(Vector2.ZERO, radius * 1.48, 0.03, PI - 0.03, 90, Color(color.r, color.g, color.b, 0.35), 13)
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	if font == null: return
	buttons.clear()
	background()
	match game.state:
		"menu": menu()
		"map": campaign()
		"hangar": hangar()
		"briefing": briefing()
		"settings": settings()
		"battle": battle()
		"pause", "victory", "defeat":
			battle()
			draw_rect(Rect2(0, 0, 1440, 900), Color(0.01, 0.04, 0.08, 0.83))
			buttons.clear()
			outcome()
	if game.toast_time > 0:
		panel(Rect2(130, 847, 1180, 36), Color("173746"), 10, Color("326673"))
		centered(game.toast, Rect2(140, 847, 1160, 36), 16)

func heading(title: String, subtitle: String) -> void:
	text("ОРБИТАЛЬНЫЙ РУБЕЖ", Vector2(64, 45), 16, CYAN)
	text(title, Vector2(64, 99), 35)
	text(subtitle, Vector2(65, 130), 17, MUTED)
	button("В меню", Rect2(1248, 49, 128, 43), "menu", "", false, false, 17)

func menu() -> void:
	text("ORBITAL FRONT  /  САДОВАЯ ОБОРОНА В КОСМОСЕ", Vector2(100, 73), 16, CYAN)
	panel(Rect2(99, 155, 212, 30), Color("14363e"), 15, Color("2b575d"))
	centered("КАМПАНИЯ · 50 МИССИЙ", Rect2(99, 155, 212, 30), 13, CYAN)
	text("ОРБИТАЛЬНЫЙ", Vector2(94, 260), 61)
	text("РУБЕЖ", Vector2(94, 327), 65, CYAN)
	paragraph("Выращивайте роботов из семян. Собирайте энергию. Защитите станцию от киборгов.", Vector2(100, 371), 620, 20)
	var count: int = game.store.data.completed.size()
	button("НАЧАТЬ КАМПАНИЮ" if count == 0 else ("ПОВТОРИТЬ ФИНАЛ" if count == 50 else "ПРОДОЛЖИТЬ · МИССИЯ %02d" % game.store.next_level()), Rect2(100, 444, 472, 60), "continue", "", true, false, 22)
	button("Карта 50 уровней", Rect2(100, 522, 228, 52), "map")
	button("Ангар роботов", Rect2(344, 522, 228, 52), "hangar")
	button("Настройки и помощь", Rect2(100, 591, 472, 48), "settings", "", false, false, 18)
	text("Семена: %d / 53   •   Завершено: %d / 50" % [game.store.unlocked().size(), count], Vector2(100, 685), 18, MUTED)
	panel(Rect2(900, 535, 360, 112), Color("122b3d"), 25, Color("376174"), 2)
	icon("reactor", Vector2(934, 521), Vector2(135, 151))
	icon("pulse", Vector2(1090, 524), Vector2(166, 166))
	icon("drone", Vector2(1242, 571), Vector2(106, 120))
	text("ВАША СТАНЦИЯ. ВАШ НАБОР.", Vector2(895, 705), 18, CYAN)
	paragraph("9 классов роботов, 53 семени, боссы, ЭМИ и планеты. Каждая победа открывает новый чертёж.", Vector2(895, 739), 400, 17)
	for i in range(3):
		var rect = Rect2(100 + i * 242, 739, 223, 76)
		panel(rect, Color("102330"), 13)
		text(["50 УРОВНЕЙ", "НОВОЕ СЕМЯ", "ПРОГРЕСС"][i], rect.position + Vector2(17, 29), 17, CYAN)
		text(["Пять секторов космоса", "За каждую первую победу", "Сохраняется на диске"][i], rect.position + Vector2(17, 55), 13, MUTED)

func campaign() -> void:
	heading("КАРТА КАМПАНИИ", "Пройдите миссию, чтобы открыть следующую. Завершённые можно переигрывать.")
	text("СЕКТОР %d / 5 · %s" % [game.level_page + 1, OrbitContent.SECTORS[game.level_page]], Vector2(149, 202), 23, Color(OrbitContent.COLORS[game.level_page]))
	for i in range(10):
		var number = game.level_page * 10 + i + 1
		var mission = OrbitContent.level(number)
		var rect = Rect2(148 + (i % 5) * 230, 239 + int(i / 5) * 211, 212, 187)
		var unlocked: bool = game.store.accessible(number)
		var completed: bool = game.store.data.completed.has(str(number))
		panel(rect, Color("163344") if unlocked else Color("101f2d"), 15, CYAN if completed else LINE, 2 if completed else 1)
		text("%02d" % number, rect.position + Vector2(17, 49), 35, INK if unlocked else Color("466071"))
		if mission.boss:
			panel(Rect2(rect.position + Vector2(127, 17), Vector2(67, 23)), Color("502f3c"), 7, Color("a36276"))
			centered("БОСС", Rect2(rect.position + Vector2(127, 17), Vector2(67, 23)), 12, Color("ffb9ab"))
		paragraph(mission.name, rect.position + Vector2(17, 82), 182, 16, INK if unlocked else MUTED, 22)
		text(mission.mode_name, rect.position + Vector2(17, 135), 12, MUTED)
		if completed:
			var rating: int = game.store.data.completed[str(number)]
			for s in range(3): star(rect.position + Vector2(27 + s * 28, 161), 9, Color("f6ca7d") if s < rating else LINE)
		else:
			text("НАЧАТЬ" if unlocked else "ЗАКРЫТО", rect.position + Vector2(17, 166), 13, CYAN if unlocked else MUTED)
		buttons.append({"rect": rect, "action": "level", "value": number, "disabled": not unlocked})
	button("← Предыдущий сектор", Rect2(148, 716, 252, 49), "map_page", -1, false, game.level_page == 0, 17)
	button("Следующий сектор →", Rect2(1038, 716, 260, 49), "map_page", 1, false, game.level_page == 4, 17)
	centered("%d / 50 завершено   ·   %d семян в коллекции" % [game.store.data.completed.size(), game.store.unlocked().size()], Rect2(445, 714, 552, 51), 18, MUTED)

func seed_card(id: String, rect: Rect2, command: String, equipped: bool = false, locked: bool = false, key: String = "") -> void:
	var robot: Dictionary = game.robots[id]
	var hover = rect.has_point(get_global_mouse_position())
	panel(rect, Color("204256") if hover and not locked else Color("132b3b"), 13, CYAN if equipped else LINE, 2 if equipped else 1)
	if key != "": text(key, rect.position + Vector2(10, 19), 12, MUTED)
	icon(robot.kind, rect.position + Vector2(44, rect.size.y * 0.51), Vector2(67, 72), Color(0.35, 0.44, 0.53) if locked else Color.WHITE)
	var name: String = robot.name
	var size = 15
	while font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > rect.size.x - 88 and size > 11: size -= 1
	text(name, rect.position + Vector2(82, 30), size, MUTED if locked else INK)
	text("МИССИЯ %02d" % robot.unlock if locked else "%d ЭНЕРГИИ" % robot.cost, rect.position + Vector2(82, 54), 12, MUTED if locked else CYAN)
	if rect.size.y > 90:
		text("T%d  ·  %s" % [robot.tier, "В НАБОРЕ" if equipped else ("ЗАКРЫТО" if locked else "ДОСТУПЕН")], rect.position + Vector2(82, 77), 10, MUTED)
	if command != "": buttons.append({"rect": rect, "action": command, "value": id, "disabled": false})

func hangar() -> void:
	heading("АНГАР РОБОТОВ", "Соберите набор из 6 семян. Нажмите на робота в коллекции, затем добавьте его в набор.")
	button("← Назад", Rect2(1195, 111, 180, 37), "hangar_back", "", false, false, 16)
	text("НАБОР ДЛЯ МИССИИ   %d / 6" % game.store.data.deck.size(), Vector2(71, 192), 16, CYAN)
	for i in range(6):
		var rect = Rect2(70 + i * 191, 213, 178, 86)
		if i < game.store.data.deck.size(): seed_card(game.store.data.deck[i], rect, "equip", true, false, str(i + 1))
		else:
			panel(rect, Color("0e202e"), 12)
			centered("ПУСТО", rect, 14, Color("496577"))
	text("КОЛЛЕКЦИЯ   %d / 53" % game.store.unlocked().size(), Vector2(71, 339), 16, CYAN)
	var start = game.collection_page * 12
	for i in range(12):
		var index = start + i
		if index >= game.catalogue.size(): break
		var robot: Dictionary = game.catalogue[index]
		var rect = Rect2(70 + (i % 4) * 232, 363 + int(i / 4) * 119, 217, 105)
		seed_card(robot.id, rect, "inspect", robot.id in game.store.data.deck, robot.id not in game.store.unlocked())
		if game.focus_robot == robot.id: panel(rect.grow(3), Color.TRANSPARENT, 15, Color("f6bf72"), 2)
	button("←", Rect2(70, 745, 74, 41), "collection_page", -1, false, game.collection_page == 0, 23)
	button("→", Rect2(925, 745, 74, 41), "collection_page", 1, false, game.collection_page == 4, 23)
	centered("Страница %d / 5" % (game.collection_page + 1), Rect2(379, 745, 309, 41), 17, MUTED)
	panel(Rect2(1039, 342, 331, 462), Color("142f42"), 19)
	var robot: Dictionary = game.robots[game.focus_robot]
	var available = robot.id in game.store.unlocked()
	icon(robot.kind, Vector2(1205, 438), Vector2(123, 138))
	text(robot.name, Vector2(1061, 539), 23)
	paragraph(robot.description, Vector2(1061, 575), 288, 17)
	text("Энергия: %d   ·   Броня: %d" % [robot.cost, int(robot.hp)], Vector2(1061, 647), 15, CYAN)
	text("Урон: %d   ·   Интервал: %.1f с" % [int(robot.damage), robot.interval], Vector2(1061, 675), 15, MUTED)
	if not available: text("Награда за миссию %02d" % robot.unlock, Vector2(1061, 715), 16, Color("f6bf72"))
	button("СНЯТЬ ИЗ НАБОРА" if robot.id in game.store.data.deck else "ДОБАВИТЬ В НАБОР", Rect2(1061, 744, 287, 41), "equip", robot.id, true, not available, 16)

func briefing() -> void:
	heading("МИССИЯ %02d · %s" % [game.mission.number, game.mission.name], game.mission.sector_name)
	panel(Rect2(80, 201, 725, 268), Color("122c3d"), 22)
	text(game.mission.mode_name.to_upper(), Vector2(112, 246), 26, CYAN)
	paragraph(game.mission.description, Vector2(112, 291), 644, 21, INK, 31)
	text("Дорожек: %d     Волн: %d     Начальная энергия: %d" % [game.mission.lanes.size(), game.mission.waves.size(), game.mission.start_energy], Vector2(112, 390), 19, MUTED)
	text("БОСС В ФИНАЛЬНОЙ ВОЛНЕ" if game.mission.boss else "Собирайте энергию и берегите аварийные дроны.", Vector2(112, 434), 16, Color("f6bf72"))
	panel(Rect2(879, 201, 461, 268), Color("142d3e"), 22)
	var reward: Dictionary = game.robots[game.mission.reward]
	text("НАГРАДА ЗА ПЕРВУЮ ПОБЕДУ", Vector2(910, 244), 16, CYAN)
	icon(reward.kind, Vector2(976, 331), Vector2(110, 119))
	text(reward.name, Vector2(1059, 319), 22)
	paragraph(reward.description, Vector2(1059, 354), 247, 15, MUTED, 22)
	text("Каждый из 50 уровней открывает новое семя.", Vector2(910, 433), 15, MUTED)
	text("ВАШ НАБОР", Vector2(81, 520), 17, CYAN)
	for i in range(game.store.data.deck.size()): seed_card(game.store.data.deck[i], Rect2(80 + i * 215, 545, 202, 101), "", false, false, str(i + 1))
	button("В БОЙ", Rect2(80, 707, 394, 64), "launch", "", true, false, 26)
	button("Изменить набор", Rect2(494, 707, 262, 64), "hangar", "", false, false, 20)
	button("Карта кампании", Rect2(779, 707, 263, 64), "map", "", false, false, 20)

func settings() -> void:
	heading("НАСТРОЙКИ И ПОМОЩЬ", "Игра работает без интернета. Прогресс автоматически сохраняется на этом компьютере.")
	panel(Rect2(91, 200, 789, 595), Color("132c3c"), 22)
	text("КАК ЗАЩИЩАТЬ СТАНЦИЮ", Vector2(123, 252), 26, CYAN)
	paragraph("Выберите семя и нажмите на свободную клетку. Реакторы производят энергию: собирайте светящиеся капсулы кликом. Стрелки атакуют по своей дорожке, а щиты держат удар. Аварийный дрон спасёт дорожку один раз; второй прорыв означает поражение.", Vector2(123, 296), 718, 20, INK, 30)
	text("УПРАВЛЕНИЕ", Vector2(123, 494), 22, CYAN)
	paragraph("1–6: семена из набора. 7 или правая кнопка мыши: разбор робота с возвратом 25% энергии. Пробел / Esc: пауза. Enter: начать или продолжить. M: включить или выключить звук.", Vector2(123, 536), 718, 19, MUTED, 29)
	paragraph("За первую победу выдаётся новое семя. Три звезды — без потерь аварийных дронов, две — потеря не более двух, одна — остальные победы. В ангаре можно менять набор и изучать способности.", Vector2(123, 659), 718, 18, MUTED, 28)
	panel(Rect2(935, 200, 405, 292), Color("132c3c"), 22)
	text("ЗВУК", Vector2(970, 252), 25, CYAN)
	button("Музыка и эффекты: %s" % ("включены" if game.store.data.sound else "выключены"), Rect2(968, 278, 337, 57), "sound", "", true, false, 17)
	paragraph("Сохранение: user://orbit_progress.json. Godot хранит его в папке данных приложения «Орбитальный рубеж».", Vector2(970, 389), 334, 17, MUTED, 25)

func battle() -> void:
	panel(Rect2(24, 18, 1392, 85), Color(0.055, 0.11, 0.17, 0.94), 18)
	text("МИССИЯ %02d · %s" % [game.mission.number, game.mission.name], Vector2(47, 53), 25)
	text("%s   /   %s" % [game.mission.sector_name, game.mission.mode_name], Vector2(48, 81), 15, MUTED)
	panel(Rect2(1123, 34, 266, 51), Color("174456"), 15, Color("3b8ba0"))
	energy_icon(Vector2(1155, 59), 17)
	text(str(game.energy), Vector2(1183, 69), 28)
	text("ЭНЕРГИЯ", Vector2(1274, 65), 14, CYAN)
	for i in range(6):
		var rect = Rect2(36 + i * 181, 127, 170, 101)
		if i < game.deck.size():
			var id: String = game.deck[i]
			seed_card(id, rect, "select", game.selected == id, false, str(i + 1))
			if game.cooldowns[id] > 0:
				var ratio: float = game.cooldowns[id] / game.robots[id].cooldown
				panel(Rect2(rect.position + Vector2(8, 93), Vector2(154 * ratio, 4)), Color("518b98"), 2, Color.TRANSPARENT, 0)
		else:
			panel(rect, Color("0d202e"), 12)
			centered("Нет семени", rect, 14, Color("466073"))
	text("ВОЛНА %d / %d" % [game.wave_index, game.mission.waves.size()], Vector2(1148, 151), 20, CYAN)
	var status = "%d киборгов в пути" % (game.pending.size() + game.enemies.size())
	if game.pending.is_empty() and game.enemies.is_empty(): status = "Подготовка: %d с" % int(ceil(game.wave_wait))
	text(status, Vector2(1148, 178), 14, MUTED)
	button("Пауза", Rect2(1148, 193, 94, 35), "pause", "", false, false, 15)
	button("Звук: %s" % ("вкл" if game.store.data.sound else "выкл"), Rect2(1250, 193, 132, 35), "sound", "", false, false, 14)
	text("ПЛАТФОРМА ОБОРОНЫ", Vector2(242, 272), 16, CYAN)
	button("[7] Разбор", Rect2(48, 247, 151, 34), "select", "recycle", game.selected == "recycle", false, 15)
	text("Роботы действуют по своей дорожке", Vector2(1001, 272), 14, MUTED)
	panel(OrbitGame.BOARD.grow(10), Color("0f2738"), 20, Color("31566c"), 2)
	for row in range(5):
		var active = row in game.mission.lanes
		for col in range(9):
			var cell = Vector2i(col, row)
			var rect = Rect2(OrbitGame.BOARD.position + Vector2(cell) * OrbitGame.CELL, OrbitGame.CELL).grow(-3)
			var color = Color("193747") if (col + row) % 2 == 0 else Color("173142")
			if not active: color = Color("101f2b")
			panel(rect, color, 10, Color("254756") if active else Color("192d3c"))
			draw_line(rect.position + Vector2(12, 12), rect.position + Vector2(25, 12), Color("3c6371"), 2)
			draw_line(rect.end - Vector2(12, 12), rect.end - Vector2(25, 12), Color("3c6371"), 2)
			if cell in game.mission.blocked:
				text("×", game.center(cell) + Vector2(-15, 14), 43, Color("756b68"))
				text("ОБЛОМКИ", rect.position + Vector2(23, 77), 11, MUTED)
		text("0%d" % (row + 1), Vector2(64, game.center(Vector2i(0, row)).y + 7), 17, MUTED)
		if active:
			icon("guard", Vector2(172, game.center(Vector2i(0, row)).y), Vector2(69, 75), Color.WHITE if game.guards[row] else Color(0.22, 0.28, 0.32))
	var hovered: Vector2i = game.cell_at(get_global_mouse_position())
	if game.state == "battle" and game.can_use_cell(hovered):
		panel(Rect2(OrbitGame.BOARD.position + Vector2(hovered) * OrbitGame.CELL, OrbitGame.CELL).grow(-4), Color(0.3, 0.8, 0.8, 0.08), 10, CYAN, 2)
		if not game.plants.has(hovered) and game.selected != "recycle":
			icon(game.robots[game.selected].kind, game.center(hovered), Vector2(81, 86), Color(1, 1, 1, 0.3))
	for cell in game.plants:
		var bot: Dictionary = game.plants[cell]
		var robot: Dictionary = game.robots[bot.id]
		var point: Vector2 = game.center(cell)
		draw_circle(point + Vector2(0, 30), 26, Color(0, 0, 0, 0.17))
		icon(robot.kind, point + Vector2(0, sin(game.ui_time * 2 + cell.x) * 1.5), Vector2(84, 87), Color(0.6, 0.57, 0.85) if bot.disabled > 0 else (Color(1.35, 1.4, 1.4) if bot.flash > 0 else Color.WHITE))
		if robot.tier > 0:
			draw_circle(point + Vector2(-32, -31), 9, Color(robot.color))
			text(str(robot.tier), point + Vector2(-36, -27), 11, Color("14232f"))
		if bot.hp < robot.hp: health(point + Vector2(-29, 35), 58, bot.hp / robot.hp, CYAN)
		if bot.disabled > 0: text("ЭМИ", point + Vector2(-15, -38), 13, Color("c9aaf9"))
	for enemy in game.enemies:
		var point = Vector2(enemy.x, game.center(Vector2i(0, enemy.row)).y)
		var big = enemy.kind == "boss"
		icon(enemy.kind, point + Vector2(sin(game.ui_time * 7 + enemy.id) * 1.5, 0), Vector2(104, 107) if big else Vector2(80, 90), Color(1.5, 1.0, 0.9) if enemy.flash > 0 else (Color(0.58, 0.85, 1.25) if enemy.slow > 0 else Color.WHITE))
		if big or enemy.hp < enemy.max_hp: health(point + Vector2(-30, -43), 60, enemy.hp / enemy.max_hp, Color("f7a888"))
	for bullet in game.bullets:
		var color = Color("92d9fd") if bullet.kind == "cryo" else (Color("f6ba7c") if bullet.kind == "mortar" else CYAN)
		draw_line(bullet.pos - Vector2(16 if bullet.kind == "rail" else 7, 0), bullet.pos, Color(color.r, color.g, color.b, 0.45), 6)
		draw_circle(bullet.pos, 7 if bullet.kind == "mortar" else 4, color)
	for particle in game.particles:
		var color: Color = particle.color
		color.a = particle.life * 2
		draw_rect(Rect2(particle.pos, Vector2(3, 3)), color)
	for fx in game.effects:
		var color: Color = fx.color
		color.a = fx.life * 1.6
		if fx.get("beam", false): draw_line(fx.pos - Vector2(600, 0), fx.pos + Vector2(600, 0), color, fx.life * 27)
		else: draw_arc(fx.pos, fx.radius * (1.0 - fx.life), 0, TAU, 64, color, 3)
	for orb in game.orbs: energy_icon(orb.pos + Vector2(0, sin(game.ui_time * 2 + orb.age) * 3), 22, clampf(15 - orb.age, 0, 1))
	panel(Rect2(48, 801, 1340, 36), Color("142d3e"), 10)
	centered("1–6: семена   ·   7 / ПКМ: разбор   ·   Пробел: пауза   ·   M: звук   ·   Собирайте энергокапсулы кликом", Rect2(48, 801, 1340, 36), 16, MUTED)

func health(point: Vector2, width: float, ratio: float, color: Color) -> void:
	panel(Rect2(point, Vector2(width, 5)), Color("0b1823"), 2, Color.TRANSPARENT, 0)
	panel(Rect2(point, Vector2(width * clampf(ratio, 0, 1), 5)), color, 2, Color.TRANSPARENT, 0)

func outcome() -> void:
	panel(Rect2(330, 182, 780, 600), Color("122c3e"), 28, Color("3f7282"), 2)
	if game.state == "pause":
		centered("СТАНЦИЯ НА ПАУЗЕ", Rect2(380, 223, 680, 73), 36)
		centered("Роботы ждут ваших команд.", Rect2(380, 320, 680, 43), 20, MUTED)
		button("ПРОДОЛЖИТЬ", Rect2(463, 405, 514, 60), "resume", "", true, false, 24)
		button("Начать миссию заново", Rect2(463, 490, 514, 55), "retry")
		button("В главное меню", Rect2(463, 570, 514, 55), "menu")
		centered("Выход в меню прервёт текущую миссию.", Rect2(380, 686, 680, 42), 16, MUTED)
	elif game.state == "defeat":
		centered("РУБЕЖ ПРОРВАН", Rect2(380, 217, 680, 76), 36, Color("f7a888"))
		icon("boss", Vector2(720, 395), Vector2(134, 150))
		centered("Семя не потеряно. Попробуйте другую расстановку.", Rect2(371, 516, 698, 45), 20)
		centered("Реакторы в тылу, стрелки за щитами, ремонт рядом.", Rect2(371, 558, 698, 36), 17, MUTED)
		button("ПОВТОРИТЬ МИССИЮ", Rect2(428, 623, 584, 58), "retry", "", true, false, 22)
		button("Карта кампании", Rect2(428, 703, 283, 44), "map", "", false, false, 17)
		button("Ангар", Rect2(729, 703, 283, 44), "hangar", "", false, false, 17)
	else:
		centered("КАМПАНИЯ ЗАВЕРШЕНА!" if game.mission.number == 50 else "МИССИЯ ЗАВЕРШЕНА", Rect2(367, 211, 706, 66), 33, CYAN)
		for i in range(3): star(Vector2(663 + i * 57, 305), 19, Color("f6ca7d") if i < game.earned_stars else LINE)
		var reward: Dictionary = game.robots[game.mission.reward]
		panel(Rect2(405, 356, 630, 213), Color("1a3b4c"), 20, Color("4e8190"))
		icon(reward.kind, Vector2(493, 457), Vector2(117, 133))
		text("НОВОЕ СЕМЯ ПОЛУЧЕНО" if game.reward_new else "СЕМЯ УЖЕ В КОЛЛЕКЦИИ", Vector2(582, 394), 16, CYAN)
		text(reward.name, Vector2(582, 441), 30)
		paragraph(reward.description, Vector2(583, 477), 422, 18, MUTED)
		text("Найдите его в ангаре и добавьте в набор.", Vector2(582, 541), 15, MUTED)
		centered("Прогресс сохранён   ·   Очки: %d" % game.score if game.store.last_save_ok else "Ошибка сохранения — не закрывайте игру", Rect2(405, 586, 630, 34), 17, MUTED)
		button("В ГЛАВНОЕ МЕНЮ" if game.mission.number == 50 else "СЛЕДУЮЩАЯ МИССИЯ", Rect2(428, 640, 584, 55), "next", "", true, false, 22)
		button("Ангар роботов", Rect2(428, 716, 283, 40), "hangar", "", false, false, 17)
		button("Карта кампании", Rect2(729, 716, 283, 40), "map", "", false, false, 17)
