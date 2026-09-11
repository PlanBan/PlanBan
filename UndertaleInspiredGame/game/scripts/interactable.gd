extends Area2D
class_name WorldInteractable

@export_multiline var dialogue_text: String = "Die Wurzeln schweigen."
@export var story_flag: StringName = &""
@export var one_shot: bool = false

var used := false

func interact(_player: Node) -> void:
	if one_shot and used:
		return
	var dialogue := get_tree().get_first_node_in_group("dialogue_ui")
	if dialogue == null or not dialogue.has_method("show_dialogue"):
		return
	used = true
	if story_flag != &"":
		GameState.set_story_flag(story_flag, true)
	dialogue.show_dialogue(dialogue_text)
