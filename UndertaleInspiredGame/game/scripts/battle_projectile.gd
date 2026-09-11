extends Area2D
class_name BattleProjectile

@export var velocity: Vector2 = Vector2(0, 160)
@export var damage: int = 3
@export var lifetime: float = 8.0

func _process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func get_damage() -> int:
	return damage
