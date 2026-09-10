extends Area2D
class_name JungleRelic

signal collected(value: int)

@export var score_value: int = 100
@export var enabled: bool = true

func _ready() -> void:
	monitoring = enabled

func _on_body_entered(body: Node2D) -> void:
	if not enabled:
		return
	if body.is_in_group("player"):
		enabled = false
		set_deferred("monitoring", false)
		collected.emit(score_value)
		$CollectSFX.play()
		$AnimationPlayer.play("collect")
		await $AnimationPlayer.animation_finished
		queue_free()
