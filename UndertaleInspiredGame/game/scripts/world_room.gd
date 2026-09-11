extends Node2D
class_name WorldRoom

@export var room_id: StringName
@export var chapter_id: StringName = &""
@export var enter_story_flag: StringName = &""
@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	GameState.current_room = room_id
	if chapter_id != &"":
		GameState.set_chapter(chapter_id)
	if enter_story_flag != &"":
		GameState.set_story_flag(enter_story_flag, true)
	GameState.world_input_locked = false
	if GameState.next_spawn_id != &"":
		var spawn := get_node_or_null("SpawnPoints/%s" % String(GameState.next_spawn_id)) as Marker2D
		if spawn != null:
			player.global_position = spawn.global_position
	GameState.next_spawn_id = &""
