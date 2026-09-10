extends Area2D
class_name JungleExitTemple

signal entered

@export var active: bool = false

@onready var portal: Polygon2D = $Visual/Portal
@onready var rune: Label = $Visual/Rune
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var completed: bool = false

func _ready() -> void:
	_apply_state()

func set_active(value: bool) -> void:
	if completed:
		return
	var became_active := value and not active
	active = value
	_apply_state()
	if became_active:
		$GateSFX.play()

func _apply_state() -> void:
	# Godot 4.7 can reject direct monitoring changes while another Area2D
	# signal is being flushed, so this is always deferred.
	set_deferred("monitoring", active and not completed)
	if active:
		portal.color = Color(0.42, 0.9, 0.5, 0.8)
		rune.text = "OPEN"
		animation_player.play("active")
	else:
		portal.color = Color(0.16, 0.22, 0.15, 0.65)
		rune.text = "SEALED"
		animation_player.play("sealed")

func _on_body_entered(body: Node2D) -> void:
	if completed or not active:
		return
	if body.is_in_group("player"):
		completed = true
		set_deferred("monitoring", false)
		$GateSFX.play()
		entered.emit()
