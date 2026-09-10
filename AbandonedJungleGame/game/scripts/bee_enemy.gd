extends CharacterBody2D
class_name JungleBeeEnemy

signal defeated(score_value: int)

@export_category("Patrol")
@export var patrol_half_width: float = 220.0
@export var patrol_speed: float = 80.0
@export var chase_speed: float = 145.0
@export var aggro_range: float = 340.0
@export var vertical_follow_speed: float = 70.0

@export_category("Combat")
@export var max_hp: int = 2
@export var contact_damage: int = 1
@export var score_value: int = 150

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var hp: int
var spawn_position: Vector2
var direction: float = 1.0
var target: Node2D
var dead: bool = false

func _ready() -> void:
	hp = max_hp
	spawn_position = global_position
	target = get_tree().get_first_node_in_group("player") as Node2D

func _physics_process(delta: float) -> void:
	if dead:
		return
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as Node2D

	var desired_x := direction * patrol_speed
	var desired_y := 0.0
	if is_instance_valid(target):
		var to_player := target.global_position - global_position
		if to_player.length() <= aggro_range:
			direction = signf(to_player.x) if absf(to_player.x) > 1.0 else direction
			desired_x = direction * chase_speed
			desired_y = clampf(to_player.y * 1.4, -vertical_follow_speed, vertical_follow_speed)
		else:
			_patrol_turn_check()
	else:
		_patrol_turn_check()

	velocity.x = move_toward(velocity.x, desired_x, 420.0 * delta)
	velocity.y = move_toward(velocity.y, desired_y, 300.0 * delta)
	move_and_slide()
	if is_on_wall():
		direction *= -1.0
	sprite.flip_h = direction < 0.0

func _patrol_turn_check() -> void:
	if global_position.x > spawn_position.x + patrol_half_width:
		direction = -1.0
	elif global_position.x < spawn_position.x - patrol_half_width:
		direction = 1.0

func take_damage(amount: int, _from_position: Vector2 = Vector2.ZERO) -> void:
	if dead:
		return
	hp = maxi(hp - amount, 0)
	if hp <= 0:
		dead = true
		collision_layer = 0
		collision_mask = 0
		$DamageArea.monitoring = false
		animation_player.play("death")
		defeated.emit(score_value)
		await animation_player.animation_finished
		queue_free()
	else:
		animation_player.play("hurt")

func _on_damage_area_body_entered(body: Node2D) -> void:
	if dead:
		return
	if body.has_method("take_damage"):
		body.take_damage(contact_damage, global_position)
