extends AudioStreamPlayer

func _ready() -> void:
	if stream != null and not playing:
		play()

func _on_finished() -> void:
	play()
