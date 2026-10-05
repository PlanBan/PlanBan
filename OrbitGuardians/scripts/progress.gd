extends RefCounted
class_name OrbitProgress
## Campaign saves are explicit. Preferences have their own file and never save a battle.
const PREFERENCES = ["sound", "language", "music_volume", "effects_volume", "master_volume", "fullscreen", "ui_scale"]
var path = "user://astra_slot_1.json"
var settings_path = "user://astra_settings.json"
var data: Dictionary = defaults()
var notice = ""
var last_save_ok = true

static func defaults() -> Dictionary:
	return {"version": 3, "completed": {}, "deck": ["core_pulse", "core_reactor", "core_shield"], "sound": true, "language": "ru", "music_volume": 0.65, "effects_volume": 0.65, "master_volume": 0.85, "fullscreen": false, "ui_scale": 1.0, "prologue_seen": false, "core_recovered": false}

func read_json(file_path: String) -> Variant:
	if not FileAccess.file_exists(file_path): return null
	var parser = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(file_path)) != OK: return null
	return parser.data

func valid(value: Variant) -> bool:
	if not value is Dictionary: return false
	var version: Variant = value.get("version", 0)
	if not (version is float or version is int) or version < 1 or version > 3: return false
	if not value.get("completed") is Dictionary or not value.get("deck", []) is Array: return false
	for key in value.completed:
		if not str(key).is_valid_int(): return false
		if not value.completed[key] is float and not value.completed[key] is int: return false
	return true

func adopt(parsed: Dictionary, keep_preferences: bool = true) -> void:
	var prefs = preferences() if keep_preferences else {}
	data = defaults()
	for key in parsed.completed:
		var number = int(str(key))
		if number >= 1 and number <= 50: data.completed[str(number)] = clampi(int(parsed.completed[key]), 1, 3)
	for key in PREFERENCES:
		if parsed.has(key): data[key] = parsed[key]
	data.prologue_seen = parsed.get("prologue_seen", not data.completed.is_empty()) == true
	data.core_recovered = parsed.get("core_recovered", data.completed.has("50")) == true
	var safe_deck: Array = []
	for id in parsed.get("deck", []):
		if id is String and id in unlocked() and id not in safe_deck and safe_deck.size() < 6: safe_deck.append(id)
	if not safe_deck.is_empty(): data.deck = safe_deck
	for key in prefs: data[key] = prefs[key]
	sanitize_preferences()

func preferences() -> Dictionary:
	var result = {}
	for key in PREFERENCES: result[key] = data[key]
	return result

func sanitize_preferences() -> void:
	if data.language not in ["ru", "en", "de"]: data.language = "ru"
	for key in ["music_volume", "effects_volume", "master_volume"]:
		if not data[key] is float and not data[key] is int: data[key] = defaults()[key]
		data[key] = clampf(float(data[key]), 0.0, 1.0)
	data.sound = data.sound == true
	data.fullscreen = data.fullscreen == true
	if not data.ui_scale is float and not data.ui_scale is int: data.ui_scale = 1.0
	data.ui_scale = clampf(float(data.ui_scale), 0.9, 1.25)

func load_settings() -> void:
	var parsed = read_json(settings_path)
	if not parsed is Dictionary: parsed = read_json("user://orbit_progress.json")
	if parsed is Dictionary:
		for key in PREFERENCES:
			if parsed.has(key): data[key] = parsed[key]
	sanitize_preferences()

func save_settings() -> bool:
	return atomic_write(settings_path, preferences())

func new_campaign() -> void:
	var prefs = preferences()
	data = defaults()
	for key in prefs: data[key] = prefs[key]

func load_progress() -> void:
	var parsed = read_json(path)
	if not valid(parsed):
		parsed = read_json(path + ".bak")
		if not valid(parsed):
			notice = "Сохранение повреждено. Старый файл сохранён."
			return
		notice = "Прогресс восстановлен из резервной копии."
	adopt(parsed, false)

func unlocked() -> Array:
	var ids: Array = OrbitContent.STARTERS.duplicate()
	for key in data.completed: ids.append("seed_%02d" % int(key))
	return ids

func next_level() -> int:
	for number in range(1, 51):
		if not data.completed.has(str(number)): return number
	return 50

func accessible(number: int) -> bool:
	return number >= 1 and number <= 50 and (number == 1 or data.completed.has(str(number - 1)))

func complete(number: int, stars: int) -> bool:
	if not accessible(number): return false
	var first = not data.completed.has(str(number))
	data.completed[str(number)] = maxi(int(data.completed.get(str(number), 0)), clampi(stars, 1, 3))
	if first and data.deck.size() < 6: data.deck.append("seed_%02d" % number)
	return first

func slot_path(slot: int) -> String:
	return path if slot == 1 else path.trim_suffix(".json") + "_%d.json" % slot

func slot_info(slot: int) -> Dictionary:
	var payload = read_json(slot_path(slot))
	if payload is Dictionary and payload.get("format") == "astra3d" and valid(payload.get("progress")):
		return payload.get("info", {})
	return {}

func save_slot(slot: int, session: Dictionary) -> bool:
	var info = {"mission": next_level(), "completed": data.completed.size(), "time": Time.get_datetime_string_from_system(false, true), "battle": session.get("state", "") in ["battle", "pause"], "prologue": session.get("prologue", false)}
	if info.battle: info.mission = session.get("mission_number", 1)
	last_save_ok = atomic_write(slot_path(slot), {"format": "astra3d", "progress": data, "session": session, "info": info})
	return last_save_ok

func load_slot(slot: int) -> Dictionary:
	var payload = read_json(slot_path(slot))
	if not valid_slot(payload):
		payload = read_json(slot_path(slot) + ".bak")
		if not valid_slot(payload): return {}
		notice = "Прогресс восстановлен из резервной копии."
	return payload

func valid_slot(payload: Variant) -> bool:
	return payload is Dictionary and payload.get("format") == "astra3d" and valid(payload.get("progress")) and payload.get("session") is Dictionary

func atomic_write(file_path: String, payload: Dictionary) -> bool:
	var file = FileAccess.open(file_path + ".tmp", FileAccess.WRITE)
	if file == null:
		notice = "Не удалось сохранить прогресс: проверьте доступ к папке сохранений."
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	if FileAccess.file_exists(file_path):
		if read_json(file_path) != null: DirAccess.copy_absolute(file_path, file_path + ".bak")
	if DirAccess.rename_absolute(file_path + ".tmp", file_path) != OK:
		notice = "Не удалось заменить файл сохранения."
		return false
	notice = ""
	return true

func save_progress() -> bool:
	last_save_ok = atomic_write(path, data)
	return last_save_ok
