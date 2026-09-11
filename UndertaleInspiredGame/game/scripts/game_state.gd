extends Node

signal new_game_started
signal chapter_changed(chapter_id: StringName)
signal route_changed(mercy_points: int, fight_points: int)

const STARTING_HP: int = 20
const STARTING_CHAPTER: StringName = &"prologue"

var max_hp: int = STARTING_HP
var hp: int = STARTING_HP
var current_chapter: StringName = STARTING_CHAPTER
var current_room: StringName = &"moss_entrance"
var next_spawn_id: StringName = &""
var mercy_points: int = 0
var fight_points: int = 0
var story_flags: Dictionary = {}
var inventory: Array[StringName] = []
var world_input_locked: bool = false

func start_new_game() -> void:
	max_hp = STARTING_HP
	hp = max_hp
	current_chapter = STARTING_CHAPTER
	current_room = &"moss_entrance"
	next_spawn_id = &""
	mercy_points = 0
	fight_points = 0
	story_flags.clear()
	inventory.clear()
	world_input_locked = false
	new_game_started.emit()
	route_changed.emit(mercy_points, fight_points)

func set_chapter(chapter_id: StringName) -> void:
	if current_chapter == chapter_id:
		return
	current_chapter = chapter_id
	chapter_changed.emit(current_chapter)

func set_story_flag(flag_name: StringName, value: Variant = true) -> void:
	story_flags[flag_name] = value

func get_story_flag(flag_name: StringName, default_value: Variant = false) -> Variant:
	return story_flags.get(flag_name, default_value)

func record_mercy() -> void:
	mercy_points += 1
	route_changed.emit(mercy_points, fight_points)

func record_fight() -> void:
	fight_points += 1
	route_changed.emit(mercy_points, fight_points)

func heal(amount: int) -> int:
	hp = clampi(hp + amount, 0, max_hp)
	return hp

func damage(amount: int) -> int:
	hp = clampi(hp - amount, 0, max_hp)
	return hp

func get_route_name() -> StringName:
	if fight_points == 0 and mercy_points > 0:
		return &"mercy"
	if fight_points > mercy_points:
		return &"fight"
	return &"neutral"
