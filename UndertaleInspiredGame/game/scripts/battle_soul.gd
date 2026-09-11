extends Area2D
class_name BattleSoul

signal damaged(amount: int)

@export var move_speed: float = 235.0
@export var invulnerability_time: float = 0.65

var active := false
var arena_rect := Rect2(290, 230, 380, 170)
var invulnerability_timer := 0.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	visible = false

func setup(rect: Rect2) -> void:
	arena_rect = rect
	global_position = arena_rect.get_center()
	invulnerability_timer = 0.0
	active = true
	visible = true
	modulate = Color.WHITE

func deactivate() -> void:
	active = false
	visible = false

func _process(delta: float) -> void:
	if invulnerability_timer > 0.0:
		invulnerability_timer = maxf(invulnerability_timer - delta, 0.0)
		modulate.a = 0.45 if fmod(invulnerability_timer * 14.0, 2.0) < 1.0 else 1.0
	else:
		modulate.a = 1.0

	if not active:
		return

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector.length_squared() > 1.0:
		input_vector = input_vector.normalized()
	global_position += input_vector * move_speed * delta
	global_position.x = clampf(global_position.x, arena_rect.position.x + 12.0, arena_rect.end.x - 12.0)
	global_position.y = clampf(global_position.y, arena_rect.position.y + 12.0, arena_rect.end.y - 12.0)

func _on_area_entered(area: Area2D) -> void:
	if not active or invulnerability_timer > 0.0:
		return
	if not area.has_method("get_damage"):
		return
	invulnerability_timer = invulnerability_time
	damaged.emit(int(area.get_damage()))
