extends Area2D
class_name WorldBattleTrigger

@export_file("*.tres") var enemy_data_path: String
@export_file("*.tscn") var battle_scene_path: String = "res://scenes/battle/BattleScene.tscn"
@export_file("*.tscn") var return_scene_path: String
@export var return_spawn_id: StringName = &""
@export var completion_flag: StringName = &""
@export_multiline var cleared_dialogue: String = "Hier ist es still geworden."

var starting := false

func interact(_player: Node) -> void:
	if starting:
		return
	if completion_flag != &"" and bool(GameState.get_story_flag(completion_flag, false)):
		_show_cleared_dialogue()
		return
	if enemy_data_path.is_empty() or battle_scene_path.is_empty():
		return
	starting = true
	GameState.begin_battle(enemy_data_path, return_scene_path, return_spawn_id, completion_flag)
	call_deferred("_start_battle")

func _start_battle() -> void:
	get_tree().change_scene_to_file(battle_scene_path)

func _show_cleared_dialogue() -> void:
	var dialogue := get_tree().get_first_node_in_group("dialogue_ui")
	if dialogue != null and dialogue.has_method("show_dialogue"):
		dialogue.show_dialogue(cleared_dialogue)
