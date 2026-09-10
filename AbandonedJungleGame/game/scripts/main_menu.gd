extends Control

@export_file("*.tscn") var game_scene: String = "res://scenes/levels/JungleLevel.tscn"

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(game_scene)

func _on_quit_pressed() -> void:
	get_tree().quit()
