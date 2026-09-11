extends CharacterBody2D
class_name WorldPlayer

@export_category("Movement")
@export var move_speed: float = 185.0
@export var acceleration: float = 1250.0
@export var friction: float = 1500.0

@export_category("Interaction")
@export var detector_distance: float = 38.0

@onready var visuals: Node2D = $Visuals
@onready var facing_marker: Polygon2D = $Visuals/FacingMarker
@onready var interaction_detector: Area2D = $InteractionDetector
@onready var interaction_hint: Label = $UI/InteractionHint
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var last_direction := Vector2.DOWN

func _ready() -> void:
	_update_detector()

func _physics_process(delta: float) -> void:
	if GameState.world_input_locked:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		move_and_slide()
		_update_interaction_hint()
		return

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector.length_squared() > 0.01:
		input_vector = input_vector.normalized()
		last_direction = input_vector
		velocity = velocity.move_toward(input_vector * move_speed, acceleration * delta)
		_update_detector()
		facing_marker.rotation = last_direction.angle() - PI * 0.5
		if animation_player.current_animation != "walk":
			animation_player.play("walk")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		if animation_player.current_animation != "idle":
			animation_player.play("idle")

	move_and_slide()
	_update_interaction_hint()

func _unhandled_input(event: InputEvent) -> void:
	if GameState.world_input_locked:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("confirm"):
		_try_interact()

func _update_detector() -> void:
	interaction_detector.position = last_direction * detector_distance

func _find_interactable() -> Area2D:
	var best: Area2D = null
	var best_distance := INF
	for area in interaction_detector.get_overlapping_areas():
		if not area.has_method("interact"):
			continue
		var distance := global_position.distance_squared_to(area.global_position)
		if distance < best_distance:
			best_distance = distance
			best = area
	return best

func _try_interact() -> void:
	var target := _find_interactable()
	if target != null:
		target.interact(self)

func _update_interaction_hint() -> void:
	interaction_hint.visible = not GameState.world_input_locked and _find_interactable() != null
