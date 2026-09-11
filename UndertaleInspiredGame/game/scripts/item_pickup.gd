extends Area2D
class_name WorldItemPickup

@export var item_id: StringName = &"MOOSTEE"
@export var display_name: String = "Moostee"
@export var collected_flag: StringName = &"item_moostee_1"
@export_multiline var collect_dialogue: String = "Du findest Moostee.|Er kann im Kampf 6 HP heilen."
@export_multiline var empty_dialogue: String = "Hier wächst nur noch weiches Moos."

@onready var visuals: Node2D = $Visuals

func _ready() -> void:
	if collected_flag != &"" and bool(GameState.get_story_flag(collected_flag, false)):
		visuals.visible = false

func interact(_player: Node) -> void:
	if collected_flag != &"" and bool(GameState.get_story_flag(collected_flag, false)):
		_show_dialogue(empty_dialogue)
		return
	GameState.inventory.append(item_id)
	if collected_flag != &"":
		GameState.set_story_flag(collected_flag, true)
	visuals.visible = false
	_show_dialogue(collect_dialogue)

func _show_dialogue(text: String) -> void:
	var box := get_tree().get_first_node_in_group("dialogue_ui")
	if box != null and box.has_method("show_dialogue"):
		box.show_dialogue(text)
