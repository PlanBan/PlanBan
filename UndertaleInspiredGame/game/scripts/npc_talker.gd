extends Area2D
class_name NpcTalker

@export_multiline var neutral_dialogue: String = "Hallo."
@export_multiline var mercy_dialogue: String = "Du hörst anders zu als die meisten."
@export_multiline var fight_dialogue: String = "Deine Schritte klingen schwer."
@export var first_talk_flag: StringName = &""

func interact(_player: Node) -> void:
	var dialogue := neutral_dialogue
	var route := GameState.get_route_name()
	if route == &"mercy" and not mercy_dialogue.is_empty():
		dialogue = mercy_dialogue
	elif route == &"fight" and not fight_dialogue.is_empty():
		dialogue = fight_dialogue
	if first_talk_flag != &"":
		GameState.set_story_flag(first_talk_flag, true)
	_show_dialogue(dialogue)

func _show_dialogue(text: String) -> void:
	var box := get_tree().get_first_node_in_group("dialogue_ui")
	if box != null and box.has_method("show_dialogue"):
		box.show_dialogue(text)
