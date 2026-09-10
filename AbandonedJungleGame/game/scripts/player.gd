extends CharacterBody2D
class_name JunglePlayer

signal health_changed(current_hp: int, max_hp: int)
signal died

@export_category("Movement")
@export var move_speed: float = 280.0
@export var acceleration: float = 2100.0
@export var friction: float = 2400.0
@export var jump_velocity: float = -650.0
@export var gravity: float = 1600.0
@export var max_fall_speed: float = 900.0
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12
@export_range(0.2, 1.0, 0.05) var jump_release_multiplier: float = 0.55

@export_category("Dash")
@export var dash_speed: float = 620.0
@export var dash_duration: float = 0.14
@export var dash_cooldown: float = 0.65

@export_category("Combat")
@export var max_hp: int = 3
@export var attack_damage: int = 1
@export var attack_time: float = 0.28
@export var hurt_invulnerability: float = 0.75
@export var footstep_interval: float = 0.26
@export var attack_offset_x: float = 52.0
@export var weapon_offset_x: float = 14.0

@export_category("Respawn")
@export var fall_limit_y: float = 1000.0
@export var respawn_position: Vector2 = Vector2(160, 500)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_area: Area2D = $AttackArea
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var attack_arc: Line2D = $WeaponPivot/AttackArc
@onready var jump_sfx: AudioStreamPlayer2D = $Audio/Jump
@onready var footstep_sfx: AudioStreamPlayer2D = $Audio/Footstep
@onready var attack_sfx: AudioStreamPlayer2D = $Audio/Attack
@onready var hurt_sfx: AudioStreamPlayer2D = $Audio/Hurt

var hp: int
var facing: float = 1.0
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var attack_timer: float = 0.0
var hurt_timer: float = 0.0
var footstep_timer: float = 0.0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var dead: bool = false

func _ready() -> void:
	hp = max_hp
	attack_area.monitoring = false
	attack_arc.visible = false
	_update_facing_nodes()
	_play_if_needed(&"idle")
	health_changed.emit(hp, max_hp)

func _physics_process(delta: float) -> void:
	if dead:
		return

	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)
	hurt_timer = maxf(hurt_timer - delta, 0.0)
	coyote_timer = maxf(coyote_timer - delta, 0.0)
	jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

	if is_on_floor():
		coyote_timer = coyote_time

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	if attack_timer > 0.0:
		attack_timer -= delta
		if attack_timer <= 0.0:
			attack_area.set_deferred("monitoring", false)
			attack_arc.visible = false

	if dash_timer > 0.0:
		dash_timer -= delta
		velocity = Vector2(facing * dash_speed, 0.0)
		move_and_slide()
		_update_visual_state()
		return

	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)

	var input_axis := Input.get_axis("move_left", "move_right")
	if absf(input_axis) > 0.01:
		facing = signf(input_axis)
		velocity.x = move_toward(velocity.x, input_axis * move_speed, acceleration * delta)
		_update_facing_nodes()
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		_perform_jump()

	if Input.is_action_just_released("jump") and velocity.y < -120.0:
		velocity.y *= jump_release_multiplier

	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0:
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown

	if Input.is_action_just_pressed("attack") and attack_timer <= 0.0:
		_start_attack()

	move_and_slide()
	if is_on_floor():
		coyote_timer = coyote_time
	_update_visual_state()
	_update_footsteps(delta)

	if global_position.y > fall_limit_y:
		take_damage(1, Vector2.ZERO)
		if not dead:
			global_position = respawn_position
			velocity = Vector2.ZERO

func _perform_jump() -> void:
	velocity.y = jump_velocity
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	jump_sfx.play()

func _update_facing_nodes() -> void:
	sprite.flip_h = facing < 0.0
	attack_area.position.x = attack_offset_x * facing
	weapon_pivot.position.x = weapon_offset_x * facing
	weapon_pivot.scale.x = facing

func _update_footsteps(delta: float) -> void:
	if is_on_floor() and absf(velocity.x) > 45.0 and dash_timer <= 0.0 and attack_timer <= 0.0:
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			footstep_sfx.play()
			footstep_timer = footstep_interval
	else:
		footstep_timer = 0.0

func _update_visual_state() -> void:
	if dead:
		return
	if hurt_timer > 0.0:
		_play_if_needed(&"hurt")
	elif attack_timer > 0.0:
		_play_if_needed(&"attack")
	elif not is_on_floor():
		_play_if_needed(&"jump")
	elif absf(velocity.x) > 20.0:
		_play_if_needed(&"walk")
	else:
		_play_if_needed(&"idle")

func _play_if_needed(name: StringName) -> void:
	if sprite.sprite_frames.has_animation(name) and sprite.animation != name:
		sprite.play(name)
	if animation_player.has_animation(name) and animation_player.current_animation != name:
		animation_player.play(name)

func _start_attack() -> void:
	attack_timer = attack_time
	attack_sfx.play()
	attack_area.set_deferred("monitoring", true)
	attack_arc.visible = true
	_play_if_needed(&"attack")
	await get_tree().physics_frame
	for body in attack_area.get_overlapping_bodies():
		if body == self:
			continue
		if body.has_method("take_damage"):
			body.take_damage(attack_damage, global_position)

func take_damage(amount: int, from_position: Vector2) -> void:
	if dead or hurt_timer > 0.0:
		return
	hp = maxi(hp - amount, 0)
	hurt_timer = hurt_invulnerability
	hurt_sfx.play()
	if from_position != Vector2.ZERO:
		var away := signf(global_position.x - from_position.x)
		if away == 0.0:
			away = -facing
		velocity = Vector2(away * 310.0, -260.0)
	health_changed.emit(hp, max_hp)
	if hp <= 0:
		_die()
	else:
		_play_if_needed(&"hurt")

func heal_full() -> void:
	hp = max_hp
	health_changed.emit(hp, max_hp)

func _die() -> void:
	dead = true
	attack_area.set_deferred("monitoring", false)
	attack_arc.visible = false
	velocity = Vector2.ZERO
	sprite.play(&"death")
	animation_player.play(&"death")
	died.emit()
