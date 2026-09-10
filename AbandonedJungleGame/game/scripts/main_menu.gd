extends Control

@export_file("*.tscn") var game_scene: String = "res://scenes/levels/JungleLevel.tscn"

@onready var click_sfx: AudioStreamPlayer = $Audio/Click
@onready var play_button: Button = $MenuPanel/Margin/VBox/Play
@onready var quit_button: Button = $MenuPanel/Margin/VBox/Quit

var busy: bool = false

func _ready() -> void:
	play_button.grab_focus()

func _on_play_pressed() -> void:
	if busy:
		return
	busy = true
	play_button.disabled = true
	quit_button.disabled = true
	click_sfx.play()
	await get_tree().create_timer(0.08).timeout
	get_tree().change_scene_to_file(game_scene)

func _on_quit_pressed() -> void:
	if busy:
		return
	busy = true
	play_button.disabled = true
	quit_button.disabled = true
	click_sfx.play()
	await get_tree().create_timer(0.08).timeout
	get_tree().quit()
