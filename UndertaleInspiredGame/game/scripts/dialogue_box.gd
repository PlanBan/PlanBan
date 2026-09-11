extends CanvasLayer
class_name WorldDialogueBox

@onready var panel: PanelContainer = $Panel
@onready var text_label: Label = $Panel/Margin/VBox/Text
@onready var continue_label: Label = $Panel/Margin/VBox/Continue

var lines: PackedStringArray = []
var line_index := 0
var opened_frame := -1

func _ready() -> void:
	panel.visible = false

func show_dialogue(text: String) -> void:
	lines = text.split("|", false)
	if lines.is_empty():
		return
	line_index = 0
	opened_frame = Engine.get_process_frames()
	panel.visible = true
	GameState.world_input_locked = true
	_show_current_line()

func _unhandled_input(event: InputEvent) -> void:
	if not panel.visible:
		return
	if Engine.get_process_frames() <= opened_frame:
		return
	if event.is_action_pressed("confirm") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		line_index += 1
		if line_index >= lines.size():
			close_dialogue()
		else:
			_show_current_line()

func _show_current_line() -> void:
	text_label.text = lines[line_index].strip_edges()
	continue_label.text = "Z / E  ▶"

func close_dialogue() -> void:
	panel.visible = false
	GameState.world_input_locked = false
