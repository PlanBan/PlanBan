extends Node2D
class_name JungleGuardianBoss

signal health_changed(current_hp: int, max_hp: int)
signal defeated

@export var max_hp: int = 10
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hit_sfx: AudioStreamPlayer2D = $HitSFX

var hp: int = 0
var dead: bool = false

func _ready() -> void:
	hp = max_hp
	health_changed.emit(hp, max_hp)
	animation_player.play(&"idle")

func take_damage(amount: int) -> void:
	if dead:
		return
	hp = maxi(hp - amount, 0)
	health_changed.emit(hp, max_hp)
	hit_sfx.play()
	if hp <= 0:
		dead = true
		animation_player.play(&"defeat")
		defeated.emit()
	else:
		animation_player.play(&"hurt")

func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"hurt" and not dead:
		animation_player.play(&"idle")
