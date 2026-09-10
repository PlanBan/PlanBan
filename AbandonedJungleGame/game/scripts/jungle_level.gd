extends Node2D

@export_file("*.tscn") var menu_scene: String = "res://scenes/menu/MainMenu.tscn"

@onready var player: JunglePlayer = $Actors/Player
@onready var exit_temple: JungleExitTemple = $ObjectiveItems/ExitTemple
@onready var hp_label: Label = $HUD/TopBar/HP
@onready var score_label: Label = $HUD/TopBar/Score
@onready var objective_label: Label = $HUD/Objective
@onready var game_over_panel: Control = $HUD/GameOver
@onready var win_panel: Control = $HUD/Win

var score: int = 0
var enemies_remaining: int = 0
var relics_remaining: int = 0
var total_relics: int = 0

func _ready() -> void:
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	_on_player_health_changed(player.hp, player.max_hp)

	var enemies := get_tree().get_nodes_in_group("enemies")
	enemies_remaining = enemies.size()
	for enemy in enemies:
		if enemy.has_signal("defeated"):
			enemy.defeated.connect(_on_enemy_defeated)

	var relics := get_tree().get_nodes_in_group("relics")
	total_relics = relics.size()
	relics_remaining = total_relics
	for relic in relics:
		if relic.has_signal("collected"):
			relic.collected.connect(_on_relic_collected)

	exit_temple.entered.connect(_on_exit_entered)
	exit_temple.set_active(relics_remaining == 0)
	_update_score()
	_update_objective()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(menu_scene)

func _on_player_health_changed(current_hp: int, max_hp: int) -> void:
	hp_label.text = "HP  %d / %d" % [current_hp, max_hp]

func _on_enemy_defeated(value: int) -> void:
	score += value
	enemies_remaining = maxi(enemies_remaining - 1, 0)
	_update_score()

func _on_relic_collected(value: int) -> void:
	score += value
	relics_remaining = maxi(relics_remaining - 1, 0)
	_update_score()
	_update_objective()
	if relics_remaining == 0:
		exit_temple.set_active(true)

func _update_score() -> void:
	score_label.text = "SCORE  %05d" % score

func _update_objective() -> void:
	var collected := total_relics - relics_remaining
	if relics_remaining > 0:
		objective_label.text = "Ancient relics  %d / %d   •   Find them all to unseal the temple" % [collected, total_relics]
	else:
		objective_label.text = "All relics recovered   •   The temple gate is OPEN"

func _on_player_died() -> void:
	game_over_panel.visible = true
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)

func _on_exit_entered() -> void:
	win_panel.visible = true
	player.set_physics_process(false)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(menu_scene)
