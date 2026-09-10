extends Area2D
class_name BossProjectile

@export var velocity: Vector2 = Vector2.ZERO
@export var damage: int = 1
@export var lifetime: float = 5.0
@export var tint: Color = Color(0.76, 0.93, 0.43, 1.0)

@onready var visual: Polygon2D = $Visual
@onready var trail: Line2D = $Trail

func _ready() -> void:
	visual.color = tint
	trail.default_color = Color(tint.r, tint.g, tint.b, 0.42)
	if velocity.length_squared() > 0.01:
		rotation = velocity.angle()

func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()
