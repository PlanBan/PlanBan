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
var hover_values: Dictionary = {}

func _ready() -> void:
	font = ThemeDB.fallback_font

func text(value: String, point: Vector2, size: int = 20, color: Color = INK) -> void:
	value = game.l(value)
	draw_string(font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func centered(value: String, rect: Rect2, size: int = 20, color: Color = INK) -> void:
	value = game.l(value)
	var width = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	text(value, Vector2(rect.get_center().x - width / 2, rect.get_center().y + size * 0.35), size, color)

func paragraph(value: String, point: Vector2, width: float, size: int = 18, color: Color = MUTED, spacing: float = 27.0) -> void:
	value = game.l(value)
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
	var hover = rect.has_point(get_local_mouse_position()) and not disabled
	var identity = command + str(rect.position)
	var blend: float = lerpf(hover_values.get(identity, 0.0), 1.0 if hover else 0.0, 0.16)
	hover_values[identity] = blend
	var color = Color("83ede0") if primary else Color("172a40")
	color = color.lerp(Color("aafdf0") if primary else Color("29435c"), blend)
	if disabled: color = Color("101d2c")
	panel(rect, color, 8, CYAN if primary or hover else LINE, 1)
	var translated = game.l(title)
	while font.get_string_size(translated, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > rect.size.x - 22 and size > 11: size -= 1
	centered(translated, rect, size, MUTED if disabled else (Color("092d35") if primary else INK))
	if blend > 0.03: draw_line(rect.position + Vector2(12, rect.size.y - 3), rect.position + Vector2(12 + (rect.size.x - 24) * blend, rect.size.y - 3), CYAN, 2)
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

func _draw() -> void:
	if font == null: return
	buttons.clear()
	match game.state:
		"menu": menu()
		"map": campaign()
		"hangar": hangar()
		"briefing": briefing()
		"settings": settings()
		"dialogue": dialogue()
		"cinematic": cinematic()
		"travel": travel()
		"battle": battle()
		"pause", "victory", "defeat":
			battle()
			draw_rect(Rect2(-80, 0, 1600, 900), Color(0.01, 0.04, 0.08, 0.83))
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

func language_buttons(point: Vector2) -> void:
	for i in range(3):
		var code: String = ["ru", "en", "de"][i]
		button(["RU", "EN", "DE"][i], Rect2(point + Vector2(i * 60, 0), Vector2(52, 34)), "language", code, game.store.data.language == code, false, 14)

func ship(point: Vector2, scale_factor: float = 1.0, angle: float = -0.12) -> void:
	draw_set_transform(point, angle, Vector2.ONE * scale_factor)
	var pulse = 0.82 + 0.18 * sin(game.ui_time * 24)
	draw_colored_polygon(PackedVector2Array([Vector2(-50, -14), Vector2(-122 * pulse, 0), Vector2(-50, 14)]), Color(0.23, 0.87, 1.0, 0.15))
	draw_colored_polygon(PackedVector2Array([Vector2(-48, -7), Vector2(-91 * pulse, 0), Vector2(-48, 7)]), Color(0.5, 0.93, 1.0, 0.75))
	icon("ship", Vector2.ZERO, Vector2(168, 168))
	draw_set_transform(Vector2.ZERO)

func core(point: Vector2, radius: float = 45.0, stolen: bool = false) -> void:
	var color = Color("ff786d") if stolen else CYAN
	for i in range(4): draw_circle(point, radius * (1.1 + i * 0.2), Color(color.r, color.g, color.b, 0.035))
	draw_arc(point, radius * 1.1, game.ui_time * 0.4, game.ui_time * 0.4 + TAU * 0.78, 80, color, 2)
	draw_arc(point, radius * 0.82, -game.ui_time * 0.7, -game.ui_time * 0.7 + TAU * 0.62, 64, color, 1)
	var shape = PackedVector2Array()
	for i in range(6): shape.append(point + Vector2.from_angle(i * TAU / 6 + game.ui_time * 0.12) * radius * 0.64)
	draw_colored_polygon(shape, color.darkened(0.15))
	draw_circle(point, radius * 0.25, Color("efffff"))

func menu() -> void:
	text("ORBITAL FRONT", Vector2(60, 63), 20, CYAN)
	text("02 / ASTRA", Vector2(280, 63), 12, MUTED)
	language_buttons(Vector2(1170, 36))
	var count: int = game.store.data.completed.size()
	text("ИСТОРИЯ О ПОГОНЕ СКВОЗЬ ПЯТЬ МИРОВ", Vector2(60, 206), 13, CYAN)
	text("ЯДРО" if not game.store.data.core_recovered else "ЯДРО", Vector2(54, 292), 78)
	text("ПОХИЩЕНО." if not game.store.data.core_recovered else "ВОЗВРАЩЕНО.", Vector2(54, 375), 69, CYAN)
	paragraph("Наш дом погас. Их флот уходит к Нексусу. Соберите защитников, поднимите корабль и верните сердце Астра.", Vector2(62, 423), 575, 20, MUTED, 30)
	var title = "НАЧАТЬ ИСТОРИЮ" if not game.store.data.prologue_seen else ("ПОВТОРИТЬ ФИНАЛ" if count == 50 else "ПРОДОЛЖИТЬ · МИССИЯ %02d" % game.store.next_level())
	button(title, Rect2(60, 533, 488, 62), "continue", "", true, false, 21)
	button("Путешествие", Rect2(60, 613, 236, 47), "map", "", false, false, 18)
	button("Ангар роботов", Rect2(312, 613, 236, 47), "hangar", "", false, false, 18)
	button("Настройки", Rect2(60, 675, 236, 43), "settings", "", false, false, 17)
	button("Выход", Rect2(312, 675, 236, 43), "quit", "", false, false, 17)
	text("%02d / 50 МИССИЙ   ·   %d / 53 СЕМЯН" % [count, game.store.unlocked().size()], Vector2(62, 761), 13, MUTED)
	ship(Vector2(1045 + sin(game.ui_time * 0.3) * 9, 460 + sin(game.ui_time * 0.9) * 12), 2.55, -0.16 + sin(game.ui_time * 0.5) * 0.025)
	draw_line(Vector2(936, 622), Vector2(1219, 622), Color("365267"), 1)
	text("КОРАБЛЬ «ИСКРА»", Vector2(953, 653), 14, CYAN)
	text("Резервный реактор онлайн", Vector2(953, 679), 13, MUTED)
	if game.store.data.prologue_seen: button("Сюжет с начала", Rect2(953, 704, 246, 38), "story", "", false, false, 14)
	draw_line(Vector2(60, 809), Vector2(1380, 809), Color("233b52"), 1)
	for i in range(5):
		var pos = Vector2(92 + i * 274, 849)
		draw_circle(pos, 5, Color(OrbitContent.COLORS[i]))
		text(OrbitContent.PLANET_NAMES[i], pos + Vector2(16, 5), 13, MUTED)

func route_point(index: int) -> Vector2:
	var points = [Vector2(154, 350), Vector2(424, 308), Vector2(694, 350), Vector2(964, 308), Vector2(1234, 350), Vector2(1234, 570), Vector2(964, 625), Vector2(694, 570), Vector2(424, 625), Vector2(154, 570)]
	return points[index]

func campaign() -> void:
	heading("ПУТЕШЕСТВИЕ", "Следуйте за флотом машин. Каждая победа приближает ядро.")
	var accent = Color(OrbitContent.COLORS[game.level_page])
	text("ПЛАНЕТА %d / 5 · %s" % [game.level_page + 1, OrbitContent.SECTORS[game.level_page]], Vector2(72, 200), 25, accent)
	paragraph(OrbitContent.BIOME_INFO[game.level_page], Vector2(73, 235), 1250, 16)
	var curve = Curve2D.new()
	for i in range(10):
		var tangent = (route_point(mini(i + 1, 9)) - route_point(maxi(i - 1, 0))).normalized() * 55
		curve.add_point(route_point(i), -tangent, tangent)
	draw_polyline(curve.get_baked_points(), Color(0.3, 0.52, 0.62, 0.38), 3, true)
	for i in range(10):
		var number = game.level_page * 10 + i + 1
		var point = route_point(i)
		var unlocked: bool = game.store.accessible(number)
		var completed: bool = game.store.data.completed.has(str(number))
		var current = number == game.store.next_level()
		if current:
			draw_circle(point, 40 + sin(game.ui_time * 2) * 4, Color(accent.r, accent.g, accent.b, 0.08))
			draw_arc(point, 34, game.ui_time * 0.6, game.ui_time * 0.6 + TAU * 0.8, 64, accent, 2)
		draw_circle(point, 27, accent if completed else Color("132a3e"))
		draw_arc(point, 27, 0, TAU, 64, accent if unlocked else LINE, 2)
		centered("%02d" % number, Rect2(point - Vector2(27, 27), Vector2(54, 54)), 19, Color("10343c") if completed else (INK if unlocked else MUTED))
		var mission = OrbitContent.level(number)
		var label = game.l(mission.name)
		var size = 15
		while font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > 220 and size > 11: size -= 1
		panel(Rect2(point + Vector2(-114, 38), Vector2(228, 32)), Color(0.025, 0.06, 0.11, 0.90), 6, Color.TRANSPARENT, 0)
		centered(label, Rect2(point + Vector2(-114, 40), Vector2(228, 24)), size, INK if unlocked else MUTED)
		if completed:
			for n in range(3): star(point + Vector2(-19 + n * 19, 83), 6, Color("f6ca7d") if n < game.store.data.completed[str(number)] else LINE)
		elif mission.boss: centered("БОСС", Rect2(point + Vector2(-85, 68), Vector2(170, 24)), 11, Color("ffa891"))
		buttons.append({"rect": Rect2(point - Vector2(45, 40), Vector2(90, 105)), "action": "level", "value": number, "disabled": not unlocked})
	button("← Предыдущая планета", Rect2(72, 755, 269, 48), "map_page", -1, false, game.level_page == 0, 16)
	button("Следующая планета →", Rect2(1094, 755, 274, 48), "map_page", 1, false, game.level_page == 4, 16)
	button("К следующей миссии", Rect2(487, 755, 470, 48), "continue", "", true, false, 18)
	centered("%d / 50 завершено   ·   %d семян в коллекции" % [game.store.data.completed.size(), game.store.unlocked().size()], Rect2(440, 824, 560, 30), 14, MUTED)

func seed_card(id: String, rect: Rect2, command: String, equipped: bool = false, locked: bool = false, key: String = "") -> void:
	var robot: Dictionary = game.robots[id]
	var hover = rect.has_point(get_local_mouse_position())
	panel(rect, Color("204256") if hover and not locked else Color("132b3b"), 13, CYAN if equipped else LINE, 2 if equipped else 1)
	if key != "": text(key, rect.position + Vector2(10, 19), 12, MUTED)
	icon(robot.kind, rect.position + Vector2(44, rect.size.y * 0.51), Vector2(67, 72), Color(0.35, 0.44, 0.53) if locked else Color.WHITE)
	var name: String = game.l(robot.name)
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
	text("БОСС В ФИНАЛЬНОЙ ВОЛНЕ" if game.mission.boss else "Собирайте энергию и берегите аварийные барьеры.", Vector2(112, 434), 16, Color("f6bf72"))
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

func slider(title: String, key: String, y: float) -> void:
	text(title, Vector2(136, y), 18)
	text("%d %%" % int(round(game.store.data[key] * 100)), Vector2(624, y), 15, CYAN)
	var line_y = y + 27
	draw_line(Vector2(136, line_y), Vector2(671, line_y), Color("2a4055"), 6, true)
	draw_line(Vector2(136, line_y), Vector2(136 + game.store.data[key] * 535, line_y), CYAN, 6, true)
	draw_circle(Vector2(136 + game.store.data[key] * 535, line_y), 9, INK)
	buttons.append({"rect": Rect2(126, line_y - 17, 556, 34), "action": "slider", "value": key})

func settings() -> void:
	heading("НАСТРОЙКИ", "Ваш язык, ваш звук, ваш полёт.")
	panel(Rect2(92, 187, 643, 611), Color(0.06, 0.12, 0.2, 0.94), 14)
	text("АУДИО", Vector2(136, 237), 21, CYAN)
	slider("Общая громкость", "master_volume", 292)
	slider("Музыка", "music_volume", 379)
	slider("Звуковые эффекты", "effects_volume", 466)
	button("Звук: %s" % ("вкл" if game.store.data.sound else "выкл"), Rect2(136, 535, 535, 43), "sound", "", false, false, 17)
	text("ЭКРАН", Vector2(136, 633), 21, CYAN)
	button("Полноэкранный режим" if not game.store.data.fullscreen else "Оконный режим", Rect2(136, 662, 535, 47), "fullscreen", "", false, false, 17)
	text("Настройки сохраняются автоматически.", Vector2(136, 759), 14, MUTED)
	panel(Rect2(773, 187, 575, 611), Color(0.06, 0.12, 0.2, 0.94), 14)
	text("ЯЗЫК / LANGUAGE", Vector2(813, 237), 21, CYAN)
	for i in range(3):
		var code: String = ["ru", "en", "de"][i]
		button(["Русский", "English", "Deutsch"][i], Rect2(813 + i * 159, 265, 147, 44), "language", code, game.store.data.language == code, false, 16)
	text("УПРАВЛЕНИЕ", Vector2(813, 382), 21, CYAN)
	paragraph("1–6: выбор семени. 7 / ПКМ: разбор. Пробел / Esc: пауза. Enter: продолжить. M: звук.", Vector2(813, 424), 494, 18, INK, 29)
	text("ТАКТИКА", Vector2(813, 546), 21, CYAN)
	paragraph("Реакторы дают энергию. Собирайте капсулы кликом. Стрелки бьют по дорожке, щиты держат удар, механики ремонтируют соседей. Аварийный барьер спасает дорожку один раз.", Vector2(813, 588), 494, 17, MUTED, 27)
	button("← Назад", Rect2(92, 816, 237, 45), "settings_back", "", true, false, 17)

func story_stage(scene: String) -> void:
	var ruined = scene == "ruins"
	if scene in ["home", "raid", "ruins", "core"]:
		draw_arc(Vector2(720, 552), 240, PI, TAU, 100, Color("395e74"), 28)
		draw_line(Vector2(463, 552), Vector2(977, 552), Color("7c9bb1"), 7)
		for i in range(6):
			var x = 485 + i * 85
			draw_rect(Rect2(x, 483 - (i % 2) * 48, 46, 67 + (i % 2) * 48), Color("233e55"))
			draw_rect(Rect2(x + 7, 498 - (i % 2) * 48, 8, 11), Color("fa8578") if ruined else CYAN)
		if not ruined: core(Vector2(720, 422), 63, scene == "raid")
		else:
			for i in range(18):
				var p = Vector2(458 + i * 31, 520 - fmod(game.ui_time * 16 + i * 29, 135))
				draw_circle(p, 3, Color(1.0, 0.4, 0.22, 0.4))
	if scene == "raid":
		for i in range(4):
			ship(Vector2(310 + i * 278, 226 + sin(game.ui_time + i) * 10), 0.8, PI)
			draw_line(Vector2(310 + i * 278, 257), Vector2(545 + i * 95, 516), Color(1.0, 0.26, 0.22, 0.16 + sin(game.ui_time * 4 + i) * 0.08), 2)
	if scene == "ship": ship(Vector2(720, 385 + sin(game.ui_time) * 7), 2.3, -0.08)

func dialogue() -> void:
	var line = game.story_line()
	text("ASTRA / STORY", Vector2(64, 60), 15, CYAN)
	text("%02d / %02d" % [game.story_index + 1, OrbitStory.lines(game.story_context).size()], Vector2(1282, 60), 14, MUTED)
	story_stage(line.scene)
	panel(Rect2(90, 625, 1260, 213), Color(0.055, 0.11, 0.19, 0.97), 15, Color("42657b"))
	draw_circle(Vector2(165, 717), 42, Color("21384c"))
	text("R" if line.speaker == "КАПИТАН РЕЯ" else ("O" if line.speaker == "ОРИОН · БОРТОВОЙ ИИ" else "Ø"), Vector2(148, 732), 38, CYAN if line.speaker != "ВОЕНАЧАЛЬНИК НУЛЬ" else Color("ff9487"))
	text(line.speaker, Vector2(234, 665), 16, CYAN)
	var full = game.l(line.text)
	var visible = full.left(int(game.story_clock * 42))
	paragraph(visible, Vector2(234, 708), 1060, 22, INK, 33)
	button("Далее →", Rect2(1122, 848, 226, 35), "dialogue_next", "", true, false, 15)
	text("Enter / клик: продолжить", Vector2(91, 871), 13, MUTED)

func cinematic() -> void:
	var t = game.scene_clock
	text("ПАДЕНИЕ АСТРА", Vector2(64, 64), 22, Color("ff9487"))
	story_stage("ruins")
	if t < 4.6:
		var progress = clampf(t / 4.0, 0, 1)
		core(Vector2(720, 420).lerp(Vector2(1100, 186), progress), 44, true)
		ship(Vector2(1100 + maxf(0, t - 3) * 120, 170), 1.5, 0)
		centered("ОНИ ЗАБРАЛИ НАШЕ СЕРДЦЕ", Rect2(200, 719, 1040, 70), 28, Color("ffa89b"))
	else:
		ship(Vector2(500 + (t - 4.6) * 210, 430 - (t - 4.6) * 28), 1.9, -0.16)
		centered("НО ПОГОНЯ ТОЛЬКО НАЧИНАЕТСЯ", Rect2(200, 719, 1040, 70), 28, CYAN)

func travel() -> void:
	var sector = int((game.travel_target - 1) / 10)
	text("ПРЫЖОК К СЛЕДУЮЩЕЙ МИССИИ", Vector2(64, 67), 17, CYAN)
	for i in range(50):
		var x = wrapf(i * 131 - game.scene_clock * (260 + (i % 7) * 100), -80, 1520)
		var y = 137 + (i * 197) % 530
		draw_line(Vector2(x, y), Vector2(x + 80 + (i % 5) * 40, y), Color(0.4, 0.8, 1.0, 0.05 + (i % 4) * 0.025), 1)
	ship(Vector2(720 + sin(game.scene_clock * 2) * 5, 408), 2.6, -0.02)
	centered(OrbitContent.PLANET_NAMES[sector].to_upper(), Rect2(220, 620, 1000, 68), 47, Color(OrbitContent.COLORS[sector]))
	centered("МИССИЯ %02d · %s" % [game.travel_target, OrbitContent.level(game.travel_target).name], Rect2(220, 700, 1000, 40), 20, MUTED)
	button("Высадиться →", Rect2(534, 786, 373, 51), "travel_skip", "", true, false, 18)

func terrain() -> void:
	if game.prologue:
		panel(OrbitGame.BOARD.grow(12), Color("1b2d3d"), 12, Color("486477"), 2)
		for i in range(12):
			var x = 258 + i * 86
			draw_line(Vector2(x, 311), Vector2(x, 759), Color(0.28, 0.40, 0.49, 0.17), 2)
		return
	var biome: int = game.mission.sector
	var base = [Color("183b30"), Color("243e58"), Color("382524"), Color("463729"), Color("211c3f")][biome]
	draw_rect(Rect2(24, 286, 1392, 505), Color(base.r, base.g, base.b, 0.30))
	for side in [92.0, 1347.0]:
		match biome:
			0:
				for i in range(3):
					var p = Vector2(side + (i % 2) * 20 - 10, 391 + i * 139)
					draw_line(p + Vector2(0, 22), p + Vector2(0, 91), Color("2b5140"), 8)
					draw_colored_polygon(PackedVector2Array([p + Vector2(-41, 30), p + Vector2(0, -62), p + Vector2(41, 30)]), Color("245640"))
					draw_colored_polygon(PackedVector2Array([p + Vector2(-31, 0), p + Vector2(0, -67), p + Vector2(31, 0)]), Color("2d6950"))
			1:
				for i in range(3):
					var p = Vector2(side, 378 + i * 148)
					draw_colored_polygon(PackedVector2Array([p + Vector2(-48, 70), p + Vector2(-19, -39), p + Vector2(7, 12), p + Vector2(29, -14), p + Vector2(47, 70)]), Color("507d97"))
					draw_line(p + Vector2(-19, -39), p + Vector2(7, 12), Color("b1e0ef"), 3)
			2:
				var pts = PackedVector2Array()
				for i in range(15): pts.append(Vector2(side + sin(i * 1.6 + game.ui_time * 0.2) * 31, 301 + i * 33))
				draw_polyline(pts, Color("5e2c27"), 26, true)
				draw_polyline(pts, Color(1.0, 0.35, 0.07, 0.45 + sin(game.ui_time) * 0.07), 11, true)
			3:
				for i in range(5): draw_arc(Vector2(side, 361 + i * 89), 66, 3.5, 5.9, 25, Color("806a43"), 11, true)
			4:
				for i in range(4):
					var p = Vector2(side - 37, 360 + i * 104)
					draw_rect(Rect2(p, Vector2(67, 67)), Color("2d284b"))
					draw_line(p + Vector2(7, 16), p + Vector2(54, 16), Color("7864ba"), 2)
					draw_circle(p + Vector2(31, 40), 8, Color("8770c2"))
	panel(OrbitGame.BOARD.grow(12), base, 12, Color(OrbitContent.COLORS[biome]).darkened(0.55), 2)
	for i in range(27):
		var x = 252 + (i * 157) % 1020
		var y = 305 + (i * 89) % 453
		match biome:
			0:
				draw_circle(Vector2(x, y), 18 + (i % 3) * 7, Color(0.2, 0.45, 0.27, 0.18))
				for j in range(3): draw_line(Vector2(x + j * 7, y), Vector2(x + j * 7 - 4, y - 16), Color("42774c"), 1)
			1:
				draw_polyline(PackedVector2Array([Vector2(x, y), Vector2(x + 18, y - 9), Vector2(x + 33, y + 7), Vector2(x + 47, y + 3)]), Color(0.54, 0.8, 0.93, 0.28), 2, true)
			2:
				var offset = sin(game.ui_time + i) * 5
				draw_polyline(PackedVector2Array([Vector2(x, y), Vector2(x + 16, y + 13 + offset), Vector2(x + 44, y - 5), Vector2(x + 65, y + 8)]), Color(1.0, 0.28, 0.07, 0.20), 8, true)
			3: draw_arc(Vector2(x, y), 48, 3.7, 5.2, 15, Color(0.82, 0.65, 0.36, 0.2), 4, true)
			4:
				draw_polyline(PackedVector2Array([Vector2(x, y), Vector2(x + 40, y), Vector2(x + 40, y + 24), Vector2(x + 68, y + 24)]), Color(0.55, 0.36, 0.91, 0.28), 1.5, true)
				draw_circle(Vector2(x + 68, y + 24), 3, Color("7b62b4"))

func weather() -> void:
	var biome: int = game.mission.sector
	if biome == 0 or biome == 4: return
	for i in range(48):
		var x = wrapf(250 + i * 127 + game.ui_time * (8 if biome == 1 else 19), 240, 1284)
		var y = wrapf(300 + i * 71 + game.ui_time * (22 if biome == 1 else -17), 292, 772)
		draw_circle(Vector2(x, y), 1.2 + (i % 3) * 0.3, Color(0.8, 0.95, 1.0, 0.45) if biome == 1 else (Color(1.0, 0.53, 0.2, 0.4) if biome == 2 else Color(0.96, 0.77, 0.41, 0.25)))

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
	panel(Rect2(1136, 127, 259, 102), Color(0.035, 0.09, 0.15, 0.92), 10)
	text("ЭВАКУАЦИЯ" if game.prologue else "ВОЛНА %d / %d" % [game.wave_index, game.mission.waves.size()], Vector2(1148, 151), 20, CYAN)
	var status = "%d киборгов в пути" % (game.pending.size() + game.enemies.size())
	if game.pending.is_empty() and game.enemies.is_empty(): status = "Подготовка: %d с" % int(ceil(game.wave_wait))
	if game.prologue: status = "До эвакуации: %d с" % maxi(0, 32 - int(game.time))
	text(status, Vector2(1148, 178), 14, MUTED)
	button("Пауза", Rect2(1148, 193, 94, 35), "pause", "", false, false, 15)
	button("Звук: %s" % ("вкл" if game.store.data.sound else "выкл"), Rect2(1250, 193, 132, 35), "sound", "", false, false, 14)
	text("ПЛАТФОРМА ОБОРОНЫ", Vector2(242, 272), 16, CYAN)
	button("[7] Разбор", Rect2(48, 247, 151, 34), "select", "recycle", game.selected == "recycle", false, 15)
	text("Роботы действуют по своей дорожке", Vector2(1001, 272), 14, MUTED)
	terrain()
	for row in range(5):
		var active = row in game.mission.lanes
		for col in range(9):
			var cell = Vector2i(col, row)
			var rect = Rect2(OrbitGame.BOARD.position + Vector2(cell) * OrbitGame.CELL, OrbitGame.CELL).grow(-3)
			var color = Color(0.04, 0.10, 0.16, 0.22 if (col + row) % 2 == 0 else 0.34)
			if not active: color = Color("101f2b")
			panel(rect, color, 7, Color(0.57, 0.77, 0.83, 0.20) if active else Color("192d3c"))
			draw_line(rect.position + Vector2(12, 12), rect.position + Vector2(25, 12), Color("3c6371"), 2)
			draw_line(rect.end - Vector2(12, 12), rect.end - Vector2(25, 12), Color("3c6371"), 2)
			if cell in game.mission.blocked:
				text("×", game.center(cell) + Vector2(-15, 14), 43, Color("756b68"))
				text("ОБЛОМКИ", rect.position + Vector2(23, 77), 11, MUTED)
		text("0%d" % (row + 1), Vector2(64, game.center(Vector2i(0, row)).y + 7), 17, MUTED)
		if active:
			var p = Vector2(179, game.center(Vector2i(0, row)).y)
			draw_line(p - Vector2(0, 30), p + Vector2(0, 30), CYAN if game.guards[row] else LINE, 3)
			draw_arc(p, 17, -PI / 2, PI / 2, 32, Color(0.4, 0.9, 0.85, 0.3) if game.guards[row] else Color("1a2d3f"), 2)
			draw_circle(p, 4, CYAN if game.guards[row] else LINE)
	var hovered: Vector2i = game.cell_at(get_local_mouse_position())
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
		icon(game.enemy_art(enemy.kind), point + Vector2(sin(game.ui_time * 7 + enemy.id) * 1.5, 0), Vector2(104, 107) if big else Vector2(80, 90), Color(1.5, 1.0, 0.9) if enemy.flash > 0 else (Color(0.58, 0.85, 1.25) if enemy.slow > 0 else Color.WHITE))
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
	weather()
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
		button("Настройки", Rect2(463, 570, 250, 55), "settings")
		button("В главное меню", Rect2(727, 570, 250, 55), "menu")
		centered("Выход в меню прервёт текущую миссию.", Rect2(380, 686, 680, 42), 16, MUTED)
	elif game.state == "defeat":
		centered("РУБЕЖ ПРОРВАН", Rect2(380, 217, 680, 76), 36, Color("f7a888"))
		icon(game.enemy_art("boss"), Vector2(720, 395), Vector2(134, 150))
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
		button("ВЕРНУТЬ ЯДРО" if game.mission.number == 50 else "СЛЕДУЮЩАЯ МИССИЯ", Rect2(428, 640, 584, 55), "next", "", true, false, 22)
		button("Ангар роботов", Rect2(428, 716, 283, 40), "hangar", "", false, false, 17)
		button("Карта кампании", Rect2(729, 716, 283, 40), "map", "", false, false, 17)
