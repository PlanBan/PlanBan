extends Area2D
class_name StoryGate

@export var required_flag: StringName = &""
@export_file("*.tscn") var target_scene_path: String
@export var target_room_id: StringName = &""
@export var target_spawn_id: StringName = &""
@export_multiline var locked_dialogue: String = "Der Weg bleibt verschlossen."

var changing_scene := false

func interact(_player: Node) -> void:
	if changing_scene:
		return
	if required_flag != &"" and not bool(GameState.get_story_flag(required_flag, false)):
		_show_dialogue(locked_dialogue)
		return
	if target_scene_path.is_empty():
		return
	changing_scene = true
	GameState.current_room = target_room_id
	GameState.next_spawn_id = target_spawn_id
	GameState.world_input_locked = true
	call_deferred("_change_scene")

func _change_scene() -> void:
	get_tree().change_scene_to_file(target_scene_path)

func _show_dialogue(text: String) -> void:
	var dialogue := get_tree().get_first_node_in_group("dialogue_ui")
	if dialogue != null and dialogue.has_method("show_dialogue"):
		dialogue.show_dialogue(text)
