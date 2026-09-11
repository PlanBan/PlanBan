extends Control
class_name UniversalBattleScene

enum BattleState { INTRO, PLAYER_MENU, FIGHT_METER, ACT_MENU, ENEMY_TURN, RESULT, DEFEAT }

const DEFAULT_ENEMY_DATA := "res://scenes/battle/data/TestEnemy.tres"
const ARENA_RECT := Rect2(290, 230, 380, 170)

@export var projectile_scene: PackedScene

@onready var enemy_anchor: Node2D = $EnemyAnchor
@onready var enemy_name_label: Label = $EnemyHUD/EnemyName
@onready var enemy_hp_bar: ProgressBar = $EnemyHUD/EnemyHP
@onready var player_hp_label: Label = $PlayerHUD/HPLabel
@onready var dialogue_label: Label = $DialoguePanel/Margin/Text
@onready var command_bar: HBoxContainer = $CommandBar
@onready var fight_button: Button = $CommandBar/FightButton
@onready var act_button: Button = $CommandBar/ActButton
@onready var item_button: Button = $CommandBar/ItemButton
@onready var mercy_button: Button = $CommandBar/MercyButton
@onready var act_panel: PanelContainer = $ActPanel
@onready var act_button_1: Button = $ActPanel/Margin/VBox/ActButton1
@onready var act_button_2: Button = $ActPanel/Margin/VBox/ActButton2
@onready var fight_meter: Control = $FightMeter
@onready var fight_marker: ColorRect = $FightMeter/Track/Marker
@onready var arena_frame: Panel = $ArenaFrame
@onready var soul: BattleSoul = $Soul
@onready var projectile_layer: Node2D = $ProjectileLayer
@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_label: Label = $ResultPanel/Margin/VBox/ResultText
@onready var result_continue: Button = $ResultPanel/Margin/VBox/ContinueButton
@onready var defeat_panel: PanelContainer = $DefeatPanel

var enemy_data: BattleEnemyData
var enemy_hp := 1
var mercy_progress := 0
var battle_state := BattleState.INTRO
var fight_meter_position := 0.0
var fight_meter_direction := 1.0
var fight_meter_opened_frame := -1
var enemy_turn_remaining := 0.0
var bullet_timer := 0.0
var enemy_round := 0
var finished_spared := false

func _ready() -> void:
	GameState.world_input_locked = true
	_load_enemy()
	_build_enemy_visual()
	_update_hud()
	act_panel.visible = false
	fight_meter.visible = false
	arena_frame.visible = false
	result_panel.visible = false
	defeat_panel.visible = false
	soul.damaged.connect(_on_soul_damaged)
	_set_commands_enabled(false)
	dialogue_label.text = enemy_data.intro_text
	await get_tree().create_timer(0.55).timeout
	_enter_player_menu()

func _process(delta: float) -> void:
	if battle_state == BattleState.FIGHT_METER:
		_update_fight_meter(delta)
	elif battle_state == BattleState.ENEMY_TURN:
		_update_enemy_turn(delta)

func _unhandled_input(event: InputEvent) -> void:
	if battle_state == BattleState.PLAYER_MENU:
		if _handle_focused_button_confirm(event):
			return
		_handle_command_navigation(event)
	elif battle_state == BattleState.ACT_MENU:
		if _handle_focused_button_confirm(event):
			return
		_handle_act_navigation(event)

	if battle_state == BattleState.FIGHT_METER and Engine.get_process_frames() > fight_meter_opened_frame:
		if event.is_action_pressed("confirm"):
			get_viewport().set_input_as_handled()
			_resolve_fight_meter()
		elif event.is_action_pressed("cancel"):
			get_viewport().set_input_as_handled()
			fight_meter.visible = false
			_enter_player_menu()
	elif battle_state == BattleState.ACT_MENU and event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		act_panel.visible = false
		_enter_player_menu()

func _handle_focused_button_confirm(event: InputEvent) -> bool:
	if not event.is_action_pressed("confirm"):
		return false
	var focused := get_viewport().gui_get_focus_owner()
	if focused is Button and not focused.disabled:
		get_viewport().set_input_as_handled()
		(focused as Button).pressed.emit()
		return true
	return false

func _handle_command_navigation(event: InputEvent) -> void:
	var buttons: Array[Button] = [fight_button, act_button, item_button, mercy_button]
	var focused := get_viewport().gui_get_focus_owner() as Button
	var index := buttons.find(focused)
	if index < 0:
		index = 0
	if event.is_action_pressed("move_left"):
		get_viewport().set_input_as_handled()
		buttons[posmod(index - 1, buttons.size())].grab_focus()
	elif event.is_action_pressed("move_right"):
		get_viewport().set_input_as_handled()
		buttons[(index + 1) % buttons.size()].grab_focus()

func _handle_act_navigation(event: InputEvent) -> void:
	var buttons: Array[Button] = [act_button_1, act_button_2]
	var focused := get_viewport().gui_get_focus_owner() as Button
	var index := buttons.find(focused)
	if index < 0:
		index = 0
	if event.is_action_pressed("move_up") or event.is_action_pressed("move_left"):
		get_viewport().set_input_as_handled()
		buttons[posmod(index - 1, buttons.size())].grab_focus()
	elif event.is_action_pressed("move_down") or event.is_action_pressed("move_right"):
		get_viewport().set_input_as_handled()
		buttons[(index + 1) % buttons.size()].grab_focus()

func _load_enemy() -> void:
	var path := GameState.pending_battle_data_path
	if path.is_empty():
		path = DEFAULT_ENEMY_DATA
	var loaded := load(path)
	if loaded is BattleEnemyData:
		enemy_data = loaded as BattleEnemyData
	else:
		enemy_data = load(DEFAULT_ENEMY_DATA) as BattleEnemyData
	enemy_hp = enemy_data.max_hp

func _build_enemy_visual() -> void:
	for child in enemy_anchor.get_children():
		child.queue_free()
	if enemy_data.visual_scene != null:
		enemy_anchor.add_child(enemy_data.visual_scene.instantiate())

func _update_hud() -> void:
	enemy_name_label.text = enemy_data.display_name
	enemy_hp_bar.max_value = enemy_data.max_hp
	enemy_hp_bar.value = enemy_hp
	player_hp_label.text = "HP %d / %d" % [GameState.hp, GameState.max_hp]
	mercy_button.text = "VERSCHONEN ★" if mercy_progress >= enemy_data.mercy_required else "VERSCHONEN"

func _enter_player_menu() -> void:
	if enemy_hp <= 0:
		_finish_battle(false)
		return
	battle_state = BattleState.PLAYER_MENU
	arena_frame.visible = false
	soul.deactivate()
	_clear_projectiles()
	act_panel.visible = false
	fight_meter.visible = false
	command_bar.visible = true
	_set_commands_enabled(true)
	_update_hud()
	if mercy_progress >= enemy_data.mercy_required:
		dialogue_label.text = enemy_data.mercy_ready_text
	else:
		dialogue_label.text = "Was willst du tun?"
	fight_button.grab_focus()

func _set_commands_enabled(enabled: bool) -> void:
	for button in [fight_button, act_button, item_button, mercy_button]:
		button.disabled = not enabled

func _on_fight_pressed() -> void:
	if battle_state != BattleState.PLAYER_MENU:
		return
	battle_state = BattleState.FIGHT_METER
	_set_commands_enabled(false)
	fight_meter.visible = true
	fight_meter_position = 0.0
	fight_meter_direction = 1.0
	fight_meter_opened_frame = Engine.get_process_frames()
	fight_marker.position.x = 0.0
	dialogue_label.text = "Z / Enter im richtigen Moment drücken."

func _update_fight_meter(delta: float) -> void:
	fight_meter_position += fight_meter_direction * delta * 1.65
	if fight_meter_position >= 1.0:
		fight_meter_position = 1.0
		fight_meter_direction = -1.0
	elif fight_meter_position <= 0.0:
		fight_meter_position = 0.0
		fight_meter_direction = 1.0
	fight_marker.position.x = fight_meter_position * 452.0

func _resolve_fight_meter() -> void:
	if battle_state != BattleState.FIGHT_METER:
		return
	battle_state = BattleState.INTRO
	fight_meter.visible = false
	var quality := 1.0 - absf(fight_meter_position - 0.5) / 0.5
	quality = clampf(quality, 0.0, 1.0)
	var raw_damage := int(round(lerpf(float(enemy_data.fight_damage_min), float(enemy_data.fight_damage_max), quality)))
	var damage := maxi(raw_damage - enemy_data.defense, 1)
	enemy_hp = maxi(enemy_hp - damage, 0)
	GameState.set_story_flag(&"last_battle_damage", damage)
	_update_hud()
	dialogue_label.text = "%s  (-%d HP)" % [enemy_data.fight_hit_text, damage]
	if enemy_hp <= 0:
		await get_tree().create_timer(0.75).timeout
		_finish_battle(false)
	else:
		await get_tree().create_timer(0.8).timeout
		_start_enemy_turn()

func _on_act_pressed() -> void:
	if battle_state != BattleState.PLAYER_MENU:
		return
	battle_state = BattleState.ACT_MENU
	_set_commands_enabled(false)
	act_panel.visible = true
	act_button_1.text = enemy_data.act_names[0] if enemy_data.act_names.size() > 0 else "BEOBACHTEN"
	act_button_2.text = enemy_data.act_names[1] if enemy_data.act_names.size() > 1 else "ZURÜCK"
	act_button_1.disabled = enemy_data.act_names.is_empty()
	act_button_2.disabled = enemy_data.act_names.size() < 2
	act_button_1.grab_focus()

func _on_act_1_pressed() -> void:
	_resolve_act(0)

func _on_act_2_pressed() -> void:
	_resolve_act(1)

func _resolve_act(index: int) -> void:
	if battle_state != BattleState.ACT_MENU or index >= enemy_data.act_names.size():
		return
	battle_state = BattleState.INTRO
	act_panel.visible = false
	var mercy_gain := 0
	if index < enemy_data.act_mercy_values.size():
		mercy_gain = enemy_data.act_mercy_values[index]
	mercy_progress = mini(mercy_progress + mercy_gain, enemy_data.mercy_required)
	if index < enemy_data.act_responses.size():
		dialogue_label.text = enemy_data.act_responses[index]
	else:
		dialogue_label.text = "Der Gegner beobachtet dich aufmerksam."
	_update_hud()
	await get_tree().create_timer(1.0).timeout
	_start_enemy_turn()

func _on_item_pressed() -> void:
	if battle_state != BattleState.PLAYER_MENU:
		return
	battle_state = BattleState.INTRO
	_set_commands_enabled(false)
	if GameState.inventory.is_empty():
		dialogue_label.text = "Deine Tasche ist leer."
	else:
		var item := GameState.inventory.pop_front()
		GameState.heal(6)
		dialogue_label.text = "Du benutzt %s.  +6 HP" % String(item)
	_update_hud()
	await get_tree().create_timer(0.85).timeout
	_start_enemy_turn()

func _on_mercy_pressed() -> void:
	if battle_state != BattleState.PLAYER_MENU:
		return
	battle_state = BattleState.INTRO
	_set_commands_enabled(false)
	if mercy_progress >= enemy_data.mercy_required:
		_finish_battle(true)
		return
	dialogue_label.text = "Der Gegner ist noch nicht bereit, dich vorbeizulassen."
	await get_tree().create_timer(0.85).timeout
	_start_enemy_turn()

func _start_enemy_turn() -> void:
	if battle_state == BattleState.RESULT or battle_state == BattleState.DEFEAT:
		return
	battle_state = BattleState.ENEMY_TURN
	command_bar.visible = false
	act_panel.visible = false
	fight_meter.visible = false
	arena_frame.visible = true
	_clear_projectiles()
	soul.setup(ARENA_RECT)
	enemy_turn_remaining = enemy_data.enemy_turn_duration
	bullet_timer = 0.15
	enemy_round += 1
	dialogue_label.text = enemy_data.turn_text

func _update_enemy_turn(delta: float) -> void:
	enemy_turn_remaining -= delta
	bullet_timer -= delta
	if bullet_timer <= 0.0:
		bullet_timer = maxf(enemy_data.bullet_interval, 0.12)
		_spawn_bullet()
	if enemy_turn_remaining <= 0.0:
		_enter_player_menu()

func _spawn_bullet() -> void:
	if projectile_scene == null or enemy_data.attack_patterns.is_empty():
		return
	var projectile := projectile_scene.instantiate() as BattleProjectile
	if projectile == null:
		return
	projectile.damage = enemy_data.attack_damage
	projectile_layer.add_child(projectile)
	var pattern := enemy_data.attack_patterns[(enemy_round - 1) % enemy_data.attack_patterns.size()]
	var speed := enemy_data.bullet_speed
	match pattern:
		"sides":
			var from_left := randi() % 2 == 0
			projectile.position = Vector2(ARENA_RECT.position.x - 18.0 if from_left else ARENA_RECT.end.x + 18.0, randf_range(ARENA_RECT.position.y + 18.0, ARENA_RECT.end.y - 18.0))
			projectile.velocity = Vector2(speed if from_left else -speed, randf_range(-28.0, 28.0))
		"aimed":
			var side := randi() % 4
			var origin := Vector2.ZERO
			if side == 0:
				origin = Vector2(randf_range(ARENA_RECT.position.x, ARENA_RECT.end.x), ARENA_RECT.position.y - 18.0)
			elif side == 1:
				origin = Vector2(ARENA_RECT.end.x + 18.0, randf_range(ARENA_RECT.position.y, ARENA_RECT.end.y))
			elif side == 2:
				origin = Vector2(randf_range(ARENA_RECT.position.x, ARENA_RECT.end.x), ARENA_RECT.end.y + 18.0)
			else:
				origin = Vector2(ARENA_RECT.position.x - 18.0, randf_range(ARENA_RECT.position.y, ARENA_RECT.end.y))
			projectile.position = origin
			projectile.velocity = origin.direction_to(soul.global_position) * speed
		_:
			projectile.position = Vector2(randf_range(ARENA_RECT.position.x + 12.0, ARENA_RECT.end.x - 12.0), ARENA_RECT.position.y - 18.0)
			projectile.velocity = Vector2(randf_range(-35.0, 35.0), speed)

func _on_soul_damaged(amount: int) -> void:
	if battle_state != BattleState.ENEMY_TURN:
		return
	GameState.damage(amount)
	_update_hud()
	if GameState.hp <= 0:
		_show_defeat()

func _clear_projectiles() -> void:
	for child in projectile_layer.get_children():
		child.queue_free()

func _finish_battle(spared: bool) -> void:
	if battle_state == BattleState.RESULT:
		return
	battle_state = BattleState.RESULT
	finished_spared = spared
	_set_commands_enabled(false)
	command_bar.visible = false
	act_panel.visible = false
	fight_meter.visible = false
	arena_frame.visible = false
	soul.deactivate()
	_clear_projectiles()
	GameState.resolve_battle(spared)
	result_label.text = enemy_data.mercy_text if spared else enemy_data.defeat_text
	result_continue.text = "WEITER"
	result_panel.visible = true
	result_continue.grab_focus()

func _show_defeat() -> void:
	if battle_state == BattleState.DEFEAT:
		return
	battle_state = BattleState.DEFEAT
	command_bar.visible = false
	act_panel.visible = false
	fight_meter.visible = false
	arena_frame.visible = false
	soul.deactivate()
	_clear_projectiles()
	dialogue_label.text = "Dein Herz wird still."
	defeat_panel.visible = true
	$DefeatPanel/Margin/VBox/RetryButton.grab_focus()

func _on_result_continue_pressed() -> void:
	if battle_state != BattleState.RESULT:
		return
	GameState.return_from_battle()

func _on_retry_pressed() -> void:
	GameState.hp = GameState.max_hp
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	GameState.clear_pending_battle()
	GameState.world_input_locked = false
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")
