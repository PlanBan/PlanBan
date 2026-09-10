extends Area2D
class_name BattleSoul

signal health_changed(current_hp: int, max_hp: int)
signal defeated

@export_category("Battle movement")
@export var move_speed: float = 285.0
@export var min_position: Vector2 = Vector2(-238, -108)
@export var max_position: Vector2 = Vector2(238, 108)

@export_category("Health")
@export var max_hp: int = 6
@export var invulnerability_time: float = 0.65

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hurt_sfx: AudioStreamPlayer = $HurtSFX

var hp: int = 0
var active: bool = false
var invulnerability_left: float = 0.0

func _ready() -> void:
	hp = max_hp
	active = false
	health_changed.emit(hp, max_hp)

func _process(delta: float) -> void:
	invulnerability_left = maxf(invulnerability_left - delta, 0.0)
	if not active:
		return

	var horizontal := Input.get_axis("move_left", "move_right")
	var vertical := Input.get_axis("move_up", "move_down")
	var direction := Vector2(horizontal, vertical)
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	position += direction * move_speed * delta
	position = Vector2(
		clampf(position.x, min_position.x, max_position.x),
		clampf(position.y, min_position.y, max_position.y)
	)

func set_active(value: bool) -> void:
	active = value
	if value:
		position = Vector2.ZERO

func take_damage(amount: int) -> void:
	if not active or invulnerability_left > 0.0 or hp <= 0:
		return
	hp = maxi(hp - amount, 0)
	invulnerability_left = invulnerability_time
	hurt_sfx.play()
	animation_player.play(&"hurt")
	health_changed.emit(hp, max_hp)
	if hp <= 0:
		active = false
		defeated.emit()
