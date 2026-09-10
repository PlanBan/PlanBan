extends Node2D

enum Phase { INTRO, PLAYER_TURN, ATTACK_TIMING, ENEMY_TURN, TRANSITION, VICTORY, DEFEAT }

@export_file("*.tscn") var menu_scene: String = "res://scenes/menu/MainMenu.tscn"
@export var projectile_scene: PackedScene
@export_category("Battle pacing")
@export var intro_duration: float = 2.2
@export var enemy_turn_duration: float = 4.8
@export var attack_marker_speed: float = 1.35
@export var projectile_interval: float = 0.30

@onready var boss: JungleGuardianBoss = $Guardian
@onready var soul: BattleSoul = $BattleArena/Soul
@onready var projectile_layer: Node2D = $BattleArena/Projectiles
@onready var boss_hp_bar: ProgressBar = $HUD/BossHP
@onready var player_hp_label: Label = $HUD/PlayerHP
@onready var round_label: Label = $HUD/Round
@onready var message_label: Label = $HUD/MessagePanel/Message
@onready var fight_button: Button = $HUD/FightButton
@onready var attack_meter: Control = $HUD/AttackMeter
@onready var attack_marker: ColorRect = $HUD/AttackMeter/Marker
@onready var victory_overlay: Control = $HUD/Victory
@onready var defeat_overlay: Control = $HUD/Defeat
@onready var boss_music: AudioStreamPlayer = $BossMusic

var phase: int = Phase.INTRO
var phase_timer: float = 0.0
var spawn_timer: float = 0.0
var marker_value: float = 0.0
var marker_direction: float = 1.0
var round_index: int = 0
var side_toggle: bool = false
var confirm_lock: float = 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 4702
	boss.health_changed.connect(_on_boss_health_changed)
	boss.defeated.connect(_on_boss_defeated)
	soul.health_changed.connect(_on_soul_health_changed)
	soul.defeated.connect(_on_soul_defeated)
	boss_hp_bar.max_value = boss.max_hp
	boss_hp_bar.value = boss.hp
	_on_soul_health_changed(soul.hp, soul.max_hp)
	fight_button.visible = false
	attack_meter.visible = false
	victory_overlay.visible = false
	defeat_overlay.visible = false
	soul.visible = false
	soul.set_active(false)
	phase_timer = intro_duration
	message_label.text = "The vines close behind you.\nANCIENT WARDEN:  Return what the jungle remembers."

func _process(delta: float) -> void:
	confirm_lock = maxf(confirm_lock - delta, 0.0)
	match phase:
		Phase.INTRO:
			phase_timer -= delta
			if phase_timer <= 0.0:
				_start_player_turn()
		Phase.ATTACK_TIMING:
			_update_attack_meter(delta)
		Phase.ENEMY_TURN:
			_update_enemy_turn(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and phase != Phase.VICTORY and phase != Phase.DEFEAT:
		get_tree().change_scene_to_file(menu_scene)
	elif phase == Phase.ATTACK_TIMING and confirm_lock <= 0.0 and event.is_action_pressed("battle_confirm"):
		_resolve_attack()

func _start_player_turn() -> void:
	phase = Phase.PLAYER_TURN
	_clear_projectiles()
	soul.set_active(false)
	soul.visible = false
	attack_meter.visible = false
	fight_button.visible = true
	fight_button.disabled = false
	fight_button.grab_focus()
	round_label.text = "TURN  %02d" % (round_index + 1)
	var lines := [
		"Moss falls from the Warden's crown. The rune on its chest is exposed.",
		"The roots tighten around the chamber. The Warden is watching your stance.",
		"A low stone heartbeat shakes dust from the ceiling."
	]
	message_label.text = lines[round_index % lines.size()]

func _on_fight_pressed() -> void:
	if phase != Phase.PLAYER_TURN:
		return
	phase = Phase.ATTACK_TIMING
	fight_button.visible = false
	attack_meter.visible = true
	marker_value = 0.0
	marker_direction = 1.0
	confirm_lock = 0.18
	message_label.text = "Strike when the marker reaches the glowing center.   SPACE / Z"
	_update_marker_visual()

func _update_attack_meter(delta: float) -> void:
	marker_value += marker_direction * attack_marker_speed * delta
	if marker_value >= 1.0:
		marker_value = 1.0
		marker_direction = -1.0
	elif marker_value <= 0.0:
		marker_value = 0.0
		marker_direction = 1.0
	_update_marker_visual()

func _update_marker_visual() -> void:
	var usable_width := attack_meter.size.x - attack_marker.size.x - 12.0
	attack_marker.position.x = 6.0 + usable_width * marker_value

func _resolve_attack() -> void:
	if phase != Phase.ATTACK_TIMING:
		return
	phase = Phase.TRANSITION
	attack_meter.visible = false
	var distance_to_center := absf(marker_value - 0.5)
	var damage := 1
	if distance_to_center <= 0.075:
		damage = 3
	elif distance_to_center <= 0.20:
		damage = 2
	message_label.text = "Direct hit!" if damage == 3 else ("Solid hit." if damage == 2 else "The blade only chips the old stone.")
	boss.take_damage(damage)
	if boss.dead:
		return
	phase_timer = 0.65
	await get_tree().create_timer(phase_timer).timeout
	if phase != Phase.VICTORY and phase != Phase.DEFEAT:
		_start_enemy_turn()

func _start_enemy_turn() -> void:
	phase = Phase.ENEMY_TURN
	phase_timer = enemy_turn_duration
	spawn_timer = 0.05
	soul.visible = true
	soul.set_active(true)
	fight_button.visible = false
	attack_meter.visible = false
	message_label.text = "DODGE — survive the Warden's memory storm."

func _update_enemy_turn(delta: float) -> void:
	phase_timer -= delta
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_attack_pattern()
		spawn_timer = projectile_interval
	if phase_timer <= 0.0:
		round_index += 1
		_start_player_turn()

func _spawn_attack_pattern() -> void:
	match round_index % 3:
		0:
			_spawn_rain()
		1:
			_spawn_side_thorns()
		_:
			_spawn_crossing_vines()

func _spawn_rain() -> void:
	for i in range(2):
		var x := rng.randf_range(-225.0, 225.0)
		_spawn_projectile(Vector2(x, -132.0), Vector2(rng.randf_range(-18.0, 18.0), rng.randf_range(175.0, 220.0)), Color(0.72, 0.92, 0.40, 1))

func _spawn_side_thorns() -> void:
	side_toggle = not side_toggle
	var y := rng.randf_range(-96.0, 96.0)
	if side_toggle:
		_spawn_projectile(Vector2(-258.0, y), Vector2(235.0, rng.randf_range(-28.0, 28.0)), Color(0.92, 0.64, 0.30, 1))
	else:
		_spawn_projectile(Vector2(258.0, y), Vector2(-235.0, rng.randf_range(-28.0, 28.0)), Color(0.92, 0.64, 0.30, 1))

func _spawn_crossing_vines() -> void:
	side_toggle = not side_toggle
	if side_toggle:
		_spawn_projectile(Vector2(-258.0, -126.0), Vector2(215.0, 118.0), Color(0.52, 0.88, 0.70, 1))
		_spawn_projectile(Vector2(-258.0, 126.0), Vector2(215.0, -118.0), Color(0.52, 0.88, 0.70, 1))
	else:
		_spawn_projectile(Vector2(258.0, -126.0), Vector2(-215.0, 118.0), Color(0.52, 0.88, 0.70, 1))
		_spawn_projectile(Vector2(258.0, 126.0), Vector2(-215.0, -118.0), Color(0.52, 0.88, 0.70, 1))

func _spawn_projectile(spawn_position: Vector2, projectile_velocity: Vector2, projectile_tint: Color) -> void:
	if projectile_scene == null:
		return
	var projectile = projectile_scene.instantiate()
	projectile.position = spawn_position
	projectile.velocity = projectile_velocity
	projectile.tint = projectile_tint
	projectile_layer.add_child(projectile)

func _clear_projectiles() -> void:
	for projectile in projectile_layer.get_children():
		projectile.queue_free()

func _on_boss_health_changed(current_hp: int, max_hp: int) -> void:
	boss_hp_bar.max_value = max_hp
	boss_hp_bar.value = current_hp

func _on_soul_health_changed(current_hp: int, max_hp: int) -> void:
	player_hp_label.text = "SOUL  %d / %d" % [current_hp, max_hp]

func _on_boss_defeated() -> void:
	phase = Phase.VICTORY
	_clear_projectiles()
	soul.set_active(false)
	soul.visible = false
	fight_button.visible = false
	attack_meter.visible = false
	boss_music.stop()
	message_label.text = "The Ancient Warden lowers its roots. The temple finally accepts you."
	victory_overlay.visible = true
	$HUD/Victory/Replay.grab_focus()

func _on_soul_defeated() -> void:
	phase = Phase.DEFEAT
	_clear_projectiles()
	soul.set_active(false)
	soul.visible = false
	fight_button.visible = false
	attack_meter.visible = false
	boss_music.stop()
	message_label.text = "The chamber goes dark."
	defeat_overlay.visible = true
	$HUD/Defeat/Retry.grab_focus()

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_replay_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/JungleLevel.tscn")

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(menu_scene)
