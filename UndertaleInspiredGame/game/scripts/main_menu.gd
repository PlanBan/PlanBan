extends Control

@export_file("*.tscn") var first_scene_path: String = "res://scenes/world/MossEntrance.tscn"
@onready var play_button: Button = $MenuPanel/Margin/VBox/PlayButton
@onready var quit_button: Button = $MenuPanel/Margin/VBox/QuitButton

var changing_scene := false

func _ready() -> void:
	play_button.grab_focus()

func _on_play_button_pressed() -> void:
	if changing_scene:
		return
	changing_scene = true
	play_button.disabled = true
	quit_button.disabled = true
	GameState.start_new_game()
	get_tree().change_scene_to_file(first_scene_path)

func _on_quit_button_pressed() -> void:
	if changing_scene:
		return
	get_tree().quit()
