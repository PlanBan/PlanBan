extends Area2D
class_name JungleExitTemple

signal entered

@export var active: bool = false

@onready var portal: Polygon2D = $Visual/Portal
@onready var rune: Label = $Visual/Rune
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	_apply_state()

func set_active(value: bool) -> void:
	active = value
	_apply_state()

func _apply_state() -> void:
	monitoring = active
	if active:
		portal.color = Color(0.42, 0.9, 0.5, 0.8)
		rune.text = "OPEN"
		animation_player.play("active")
	else:
		portal.color = Color(0.16, 0.22, 0.15, 0.65)
		rune.text = "SEALED"
		animation_player.play("sealed")

func _on_body_entered(body: Node2D) -> void:
	if active and body.is_in_group("player"):
		entered.emit()
