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
		"save", "load": slots()
		"new_confirm": new_confirm()
		"exit_confirm": exit_confirm()
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



func menu() -> void:
	# A quiet translucent navigation column leaves the realtime docking bay visible.
	draw_rect(Rect2(-80, 0, 685, 900), Color(0.018, 0.045, 0.083, 0.92))
	text("ORBITAL FRONT", Vector2(54, 66), 22, CYAN)
	text("03 / ASTRA", Vector2(331, 66), 12, MUTED)
	language_buttons(Vector2(1169, 35))
	text("ТАКТИЧЕСКАЯ ОБОРОНА · ПЯТЬ МИРОВ", Vector2(54, 149), 12, CYAN)
	text("ВЕРНИ", Vector2(49, 236), 66)
	text("НАШЕ ЯДРО.", Vector2(49, 309), 58, CYAN)
	paragraph("Построй отряд. Пройди пять планет. Верни сердце Астра.", Vector2(56, 361), 493, 19, MUTED, 28)
	button("НОВАЯ ИГРА", Rect2(54, 435, 487, 56), "new_game", "", true, false, 21)
	button("ПРОДОЛЖИТЬ", Rect2(54, 505, 487, 49), "continue", "", false, not game.active_campaign, 19)
	button("Загрузить", Rect2(54, 569, 235, 46), "load", "", false, false, 17)
	button("Сохранить", Rect2(305, 569, 236, 46), "save", "", false, not game.active_campaign, 17)
	button("Маршрут", Rect2(54, 631, 235, 46), "map", "", false, not game.active_campaign, 17)
	button("Ангар роботов", Rect2(305, 631, 236, 46), "hangar", "", false, not game.active_campaign, 17)
	button("Настройки", Rect2(54, 693, 235, 42), "settings", "", false, false, 17)
	button("Выход", Rect2(305, 693, 236, 42), "quit", "", false, false, 17)
	text("СОХРАНЯЕТЕ ВЫ. КОМАНДУЕТЕ ВЫ.", Vector2(55, 794), 12, CYAN)
	text("3 ручных слота · F5: сохранить · F9: загрузить", Vector2(55, 823), 13, MUTED)
	panel(Rect2(921, 660, 388, 98), Color(0.04, 0.11, 0.18, 0.87), 9)
	text("КОРАБЛЬ «ИСКРА»", Vector2(944, 691), 17, CYAN)
	text("Резервный реактор онлайн", Vector2(944, 719), 14, MUTED)
	text("50 МИССИЙ / 53 ЧЕРТЕЖА", Vector2(944, 743), 11, MUTED)
	if game.active_campaign:
		text("%02d / 50 МИССИЙ   ·   %d / 53 СЕМЯН" % [game.store.data.completed.size(), game.store.unlocked().size()], Vector2(57, 859), 12, MUTED)
		if game.dirty: text("Есть несохранённый прогресс", Vector2(947, 799), 15, Color("ffbf82"))

func route_point(index: int) -> Vector2:
	var points = [Vector2(154, 425), Vector2(424, 389), Vector2(694, 425), Vector2(964, 389), Vector2(1234, 425), Vector2(1234, 623), Vector2(964, 659), Vector2(694, 623), Vector2(424, 659), Vector2(154, 623)]
	return points[index]

func campaign() -> void:
	heading("ПУТЕШЕСТВИЕ", "Следуйте за флотом машин. Каждая победа приближает ядро.")
	var current_sector = int((game.store.next_level() - 1) / 10)
	for sector in range(5):
		var point = Vector2(74 + sector * 262, 171)
		var accent_color = Color(OrbitContent.COLORS[sector])
		panel(Rect2(point, Vector2(244, 85)), Color(0.04, 0.1, 0.17, 0.93), 8, accent_color if sector == current_sector else LINE, 2 if sector == current_sector else 1)
		draw_circle(point + Vector2(25, 29), 8, accent_color)
		text(OrbitContent.PLANET_NAMES[sector], point + Vector2(45, 34), 18, accent_color)
		text("ВЫ ЗДЕСЬ" if sector == current_sector else ("ЯДРО / ЦЕЛЬ" if sector == 4 else "%02d — %02d" % [sector * 10 + 1, sector * 10 + 10]), point + Vector2(17, 65), 12, CYAN if sector == current_sector else MUTED)
		buttons.append({"rect": Rect2(point, Vector2(244, 85)), "action": "planet", "value": sector})
		if sector < 4: text("›", point + Vector2(249, 49), 26, MUTED)
	var accent = Color(OrbitContent.COLORS[game.level_page])
	text("ПЛАНЕТА %d / 5 · %s" % [game.level_page + 1, OrbitContent.SECTORS[game.level_page]], Vector2(72, 298), 25, accent)
	paragraph(OrbitContent.BIOME_INFO[game.level_page], Vector2(73, 330), 1250, 16)
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
			centered("СЛЕДУЮЩАЯ ЦЕЛЬ", Rect2(point + Vector2(-115, -70), Vector2(230, 27)), 12, CYAN)
			draw_line(point + Vector2(0, -34), point + Vector2(0, -43), CYAN, 2)
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
	button("← Предыдущая планета", Rect2(72, 803, 269, 48), "map_page", -1, false, game.level_page == 0, 16)
	button("Следующая планета →", Rect2(1094, 803, 274, 48), "map_page", 1, false, game.level_page == 4, 16)
	button("К следующей миссии", Rect2(487, 803, 470, 48), "journey", "", true, false, 18)
	centered("%d / 50 завершено   ·   %d семян в коллекции" % [game.store.data.completed.size(), game.store.unlocked().size()], Rect2(440, 859, 560, 30), 14, MUTED)

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
	panel(Rect2(1039, 535, 331, 269), Color(0.035, 0.085, 0.14, 0.94), 12)
	var robot: Dictionary = game.robots[game.focus_robot]
	var available = robot.id in game.store.unlocked()
	text("3D / LIVE", Vector2(1063, 356), 12, CYAN)
	text(robot.name, Vector2(1061, 569), 23)
	paragraph(robot.description, Vector2(1061, 602), 288, 17)
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
	paragraph("1–6: выбор семени. 7 / ПКМ: разбор. Пробел / Esc: пауза. Enter: продолжить. F5: сохранить. F9: загрузить. M: звук.", Vector2(813, 424), 494, 18, INK, 29)
	text("ТАКТИКА", Vector2(813, 546), 21, CYAN)
	paragraph("Реакторы дают энергию. Собирайте капсулы кликом. Стрелки бьют по дорожке, щиты держат удар, механики ремонтируют соседей. Аварийный барьер спасает дорожку один раз.", Vector2(813, 588), 494, 17, MUTED, 27)
	button("← Назад", Rect2(92, 816, 237, 45), "settings_back", "", true, false, 17)


func dialogue() -> void:
	draw_rect(Rect2(-80, 0, 1600, 85), Color(0.01, 0.03, 0.06, 0.9))
	var line = game.story_line()
	text("ASTRA / STORY", Vector2(64, 60), 15, CYAN)
	text("%02d / %02d" % [game.story_index + 1, OrbitStory.lines(game.story_context).size()], Vector2(1282, 60), 14, MUTED)
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
	draw_rect(Rect2(-80, 0, 1600, 84), Color("030a12"))
	draw_rect(Rect2(-80, 779, 1600, 121), Color("030a12"))
	text("ПАДЕНИЕ АСТРА", Vector2(60, 55), 20, Color("ff9487"))
	centered("ОНИ ЗАБРАЛИ НАШЕ СЕРДЦЕ" if game.scene_clock < 7 else "НО ПОГОНЯ ТОЛЬКО НАЧИНАЕТСЯ", Rect2(150, 809, 1140, 40), 26, Color("ffa89b") if game.scene_clock < 7 else CYAN)

func travel() -> void:
	var sector = int((game.travel_target - 1) / 10)
	text("ПРЫЖОК К СЛЕДУЮЩЕЙ МИССИИ", Vector2(64, 67), 17, CYAN)
	panel(Rect2(240, 600, 960, 154), Color(0.025, 0.06, 0.12, 0.9), 12)
	centered(OrbitContent.PLANET_NAMES[sector].to_upper(), Rect2(220, 620, 1000, 68), 47, Color(OrbitContent.COLORS[sector]))
	centered("МИССИЯ %02d · %s" % [game.travel_target, OrbitContent.level(game.travel_target).name], Rect2(220, 700, 1000, 40), 20, MUTED)
	button("Высадиться →", Rect2(534, 786, 373, 51), "travel_skip", "", true, false, 18)

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
	button("Сохранить", Rect2(1250, 193, 132, 35), "save", "", false, false, 14)
	text("ПЛАТФОРМА ОБОРОНЫ", Vector2(242, 272), 16, CYAN)
	button("[7] Разбор", Rect2(48, 247, 151, 34), "select", "recycle", game.selected == "recycle", false, 15)
	text("Роботы действуют по своей дорожке", Vector2(1001, 272), 14, MUTED)
	# All actors, capsules, terrain and impacts below are rendered by the 3D camera.
	for cell in game.plants:
		var bot: Dictionary = game.plants[cell]
		var robot: Dictionary = game.robots[bot.id]
		var point = game.world.project(game.world.cell_position(cell) + Vector3(0, 1.9, 0))
		if bot.hp < robot.hp: health(point - Vector2(24, 0), 48, bot.hp / robot.hp, CYAN)
		if bot.disabled > 0: text("ЭМИ", point + Vector2(-15, -10), 12, Color("c9aaf9"))
	for enemy in game.enemies:
		var point = game.world.project(game.world.logical_position(Vector2(enemy.x, game.center(Vector2i(0, enemy.row)).y), 2.35 if enemy.kind == "boss" else 1.95))
		if enemy.kind == "boss" or enemy.hp < enemy.max_hp: health(point - Vector2(25, 0), 50, enemy.hp / enemy.max_hp, Color("f7a888"))
	for row in game.mission.lanes:
		var point = game.world.project(Vector3(-10.4, 0, (row - 2) * 1.9))
		text("0%d" % (row + 1), point, 13, MUTED)
	panel(Rect2(48, 801, 1340, 36), Color("142d3e"), 10)
	centered("1–6: семена · 7 / ПКМ: разбор · Пробел: пауза · F5: сохранить · F9: загрузить", Rect2(48, 801, 1340, 36), 16, MUTED)

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
		button("Сохранить", Rect2(463, 649, 250, 47), "save")
		button("Загрузить", Rect2(727, 649, 250, 47), "load")
		centered("Сохраняйте вручную. F5 открывает слоты.", Rect2(380, 714, 680, 42), 16, MUTED)
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
		button("Сохранить победу", Rect2(428, 582, 584, 42), "save", "", false, false, 18)
		button("ВЕРНУТЬ ЯДРО" if game.mission.number == 50 else "СЛЕДУЮЩАЯ МИССИЯ", Rect2(428, 640, 584, 55), "next", "", true, false, 22)
		button("Ангар роботов", Rect2(428, 716, 283, 40), "hangar", "", false, false, 17)
		button("Карта кампании", Rect2(729, 716, 283, 40), "map", "", false, false, 17)


func slots() -> void:
	draw_rect(Rect2(-80, 0, 1600, 900), Color(0.015, 0.04, 0.08, 0.88))
	heading("СОХРАНИТЬ ИГРУ" if game.slot_mode == "save" else "ЗАГРУЗИТЬ ИГРУ", "Три ручных слота. Сохраняются маршрут, отряд и текущий бой.")
	for i in range(3):
		var rect = Rect2(83 + i * 427, 216, 401, 365)
		var info = game.store.slot_info(i + 1)
		panel(rect, Color("112637"), 12, CYAN if not info.is_empty() else LINE)
		text("СЛОТ %d" % (i + 1), rect.position + Vector2(24, 43), 21, CYAN)
		if info.is_empty():
			text("Пустой слот", rect.position + Vector2(24, 119), 23)
			paragraph("Начните новую историю и сохраните её здесь.", rect.position + Vector2(24, 166), 338, 17)
		else:
			var number = maxi(1, int(info.get("mission", 1)))
			text("МИССИЯ %02d" % number, rect.position + Vector2(24, 110), 24)
			text(OrbitContent.PLANET_NAMES[int((number - 1) / 10)], rect.position + Vector2(24, 150), 19, CYAN)
			text("Текущий бой" if info.get("battle", false) else "Кампания", rect.position + Vector2(24, 185), 17)
			text(str(info.get("time", "")), rect.position + Vector2(24, 222), 15, MUTED)
			text("%d / 50 завершено" % int(info.get("completed", 0)), rect.position + Vector2(24, 252), 14, MUTED)
		button("Сохранить сюда" if game.slot_mode == "save" else "Загрузить", Rect2(rect.position + Vector2(24, 291), Vector2(353, 49)), "slot", i + 1, true, game.slot_mode == "load" and info.is_empty(), 18)
	if game.slot_mode == "load" and game.store.valid(game.store.read_json("user://orbit_progress.json")):
		button("Импортировать кампанию версии 2.0", Rect2(83, 620, 640, 49), "legacy", "", false, false, 17)
	button("← Назад", Rect2(83, 769, 244, 49), "slot_back", "", false, false, 18)
	text("Кампания не сохраняется автоматически.", Vector2(366, 800), 17, MUTED)
	if game.pending_slot != 0:
		draw_rect(Rect2(-80, 0, 1600, 900), Color(0.01, 0.02, 0.05, 0.83))
		buttons.clear()
		panel(Rect2(342, 303, 756, 271), PANEL, 12, CYAN)
		centered("Перезаписать этот слот?", Rect2(382, 342, 676, 55), 29)
		centered("Другие слоты и старая кампания останутся на диске.", Rect2(371, 410, 699, 39), 17, MUTED)
		button("Перезаписать", Rect2(382, 479, 320, 48), "overwrite", "", true)
		button("Отмена", Rect2(722, 479, 336, 48), "cancel_overwrite")

func new_confirm() -> void:
	draw_rect(Rect2(-80, 0, 1600, 900), Color(0.015, 0.04, 0.08, 0.9))
	panel(Rect2(319, 224, 802, 417), PANEL, 14, CYAN)
	centered("НОВАЯ ИГРА", Rect2(357, 264, 726, 64), 36, CYAN)
	paragraph("Начать историю с нападения на Астра? Текущий несохранённый бой будет завершён. Все записанные слоты останутся на диске.", Vector2(361, 369), 697, 21, INK, 33)
	button("Начать с начала", Rect2(361, 545, 339, 54), "new_accept", "", true, false, 19)
	button("Назад", Rect2(720, 545, 361, 54), "slot_back", "", false, false, 19)


func exit_confirm() -> void:
	draw_rect(Rect2(-80, 0, 1600, 900), Color(0.01, 0.025, 0.06, 0.92))
	panel(Rect2(329, 269, 782, 338), PANEL, 14, CYAN)
	centered("Есть несохранённый прогресс", Rect2(365, 305, 710, 60), 30)
	centered("Сохраните игру перед выходом, чтобы продолжить этот бой.", Rect2(352, 399, 736, 40), 19, MUTED)
	button("Сохранить", Rect2(367, 480, 215, 51), "save", "", true, false, 18)
	button("Выйти", Rect2(605, 480, 215, 51), "quit_accept", "", false, false, 18)
	button("Назад", Rect2(843, 480, 230, 51), "quit_back", "", false, false, 18)
