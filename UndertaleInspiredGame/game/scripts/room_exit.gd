extends Area2D
class_name WorldRoomExit

@export_file("*.tscn") var target_scene_path: String
@export var target_room_id: StringName
@export var target_spawn_id: StringName

var changing_scene := false

func _on_body_entered(body: Node2D) -> void:
	if changing_scene or not body.is_in_group("player"):
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
