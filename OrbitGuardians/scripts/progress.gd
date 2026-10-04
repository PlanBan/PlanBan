extends RefCounted
class_name OrbitProgress

var path = "user://orbit_progress.json"
var data: Dictionary = defaults()
var notice = ""
var last_save_ok = true

func read_json(file_path: String) -> Variant:
	if not FileAccess.file_exists(file_path): return null
	var parser = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(file_path)) != OK: return null
	return parser.data

static func defaults() -> Dictionary:
	return {"version": 1, "completed": {}, "deck": ["core_pulse", "core_reactor", "core_shield"], "sound": true}

func load_progress() -> void:
	data = defaults()
	notice = ""
	if not FileAccess.file_exists(path): return
	var parsed = read_json(path)
	if not valid(parsed):
		var backup = read_json(path + ".bak")
		if valid(backup):
			parsed = backup
			notice = "Прогресс восстановлен из резервной копии."
		else:
			notice = "Сохранение повреждено. Начата новая кампания; старый файл сохранён."
			DirAccess.rename_absolute(path, path + ".corrupt-%d" % Time.get_unix_time_from_system())
			return
	var completed: Dictionary = parsed.completed
	for key in completed:
		var number = int(str(key))
		if number >= 1 and number <= 50:
			data.completed[str(number)] = clampi(int(completed[key]), 1, 3)
	data.sound = parsed.get("sound", true) == true
	var unlocked_ids = unlocked()
	var cards: Array = parsed.get("deck", [])
	var safe_deck: Array = []
	for id in cards:
		if id is String and id in unlocked_ids and id not in safe_deck and safe_deck.size() < 6: safe_deck.append(id)
	if not safe_deck.is_empty(): data.deck = safe_deck

func valid(value: Variant) -> bool:
	if not value is Dictionary: return false
	if value.get("version", 0) != 1 or not value.get("completed") is Dictionary: return false
	if not value.get("deck", []) is Array: return false
	for key in value.completed:
		if not str(key).is_valid_int(): return false
		if not value.completed[key] is float and not value.completed[key] is int: return false
	return true

func unlocked() -> Array:
	var ids: Array = OrbitContent.STARTERS.duplicate()
	for key in data.completed:
		ids.append("seed_%02d" % int(key))
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
	var seed = "seed_%02d" % number
	if first and data.deck.size() < 6: data.deck.append(seed)
	save_progress()
	return first

func save_progress() -> bool:
	last_save_ok = false
	var temporary = path + ".tmp"
	var file = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		notice = "Не удалось сохранить прогресс: проверьте доступ к папке сохранений."
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	if FileAccess.file_exists(path):
		var old = read_json(path)
		if valid(old):
			DirAccess.copy_absolute(path, path + ".bak")
	if DirAccess.rename_absolute(temporary, path) != OK:
		notice = "Не удалось заменить файл сохранения."
		return false
	last_save_ok = true
	notice = ""
	return true
