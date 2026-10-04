extends SceneTree
var game: OrbitGame
var output = "/workspace/artifacts/orbit-animation"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	game = load("res://scenes/Orbit.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.store.data = OrbitProgress.defaults()
	game.store.data.sound = false
	game.apply_settings()
	game.music.stop()
	game.start_level(1)
	game.set_process(false)
	game.wave_wait = 1000
	game.energy = 300
	game.selected = "core_reactor"
	game.deploy(Vector2i(0,2))
	game.selected = "core_pulse"
	game.deploy(Vector2i(3,2))
	game.spawn_enemy(2,"drone",1120)
	for i in range(140):
		game.advance(0.1)
		game.ui_time += 0.1
		if i == 75 and not game.orbs.is_empty():
			var orb = game.orbs[0]
			game.world.collected(orb)
			game.collect(orb.pos)
		await create_timer(0.10).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output + "/%04d.png" % i)
	print("ANIMATION CAPTURE COMPLETE / score=",game.score)
	game.quit_game(true)
