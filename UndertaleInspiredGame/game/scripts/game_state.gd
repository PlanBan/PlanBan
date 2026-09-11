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

var pending_battle_data_path: String = ""
var battle_return_scene: String = ""
var battle_return_spawn: StringName = &""
var battle_completion_flag: StringName = &""

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
	pending_battle_data_path = ""
	battle_return_scene = ""
	battle_return_spawn = &""
	battle_completion_flag = &""
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

func begin_battle(enemy_data_path: String, return_scene_path: String, return_spawn_id: StringName, completion_flag: StringName) -> void:
	pending_battle_data_path = enemy_data_path
	battle_return_scene = return_scene_path
	battle_return_spawn = return_spawn_id
	battle_completion_flag = completion_flag
	world_input_locked = true

func resolve_battle(spared: bool) -> void:
	if battle_completion_flag != &"":
		set_story_flag(battle_completion_flag, true)
	if spared:
		record_mercy()
	else:
		record_fight()

func return_from_battle() -> void:
	if battle_return_scene.is_empty():
		clear_pending_battle()
		world_input_locked = false
		get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")
		return
	next_spawn_id = battle_return_spawn
	var return_path := battle_return_scene
	clear_pending_battle()
	get_tree().change_scene_to_file(return_path)

func clear_pending_battle(clear_return: bool = true) -> void:
	pending_battle_data_path = ""
	battle_completion_flag = &""
	if clear_return:
		battle_return_scene = ""
		battle_return_spawn = &""
