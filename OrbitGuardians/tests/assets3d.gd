extends SceneTree
var checks = 0
var failures = 0
func _initialize() -> void: call_deferred("run")
func test(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets3d/manifest.json"))
	test(manifest.size() == 54, "all 54 original Blender assets exist")
	for key in manifest:
		var model = load("res://assets3d/%s.glb" % key).instantiate()
		root.add_child(model)
		await process_frame
		if not manifest[key].animations.is_empty():
			var player: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
			var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
			test(player != null and skeleton.get_bone_count() == 13, key + " has an articulated rig")
			for clip in ["Idle", "Walk", "Attack", "Deploy", "Death"]: test(player.has_animation(clip), key + ": missing " + clip)
			player.play("Walk",0)
			player.seek(0.12,true)
			var pose = skeleton.get_bone_pose_rotation(skeleton.find_bone("Thigh.L"))
			player.seek(0.65,true)
			test(not pose.is_equal_approx(skeleton.get_bone_pose_rotation(skeleton.find_bone("Thigh.L"))), key + " legs animate")
			player.play("Deploy",0)
			player.seek(0,true)
			test(skeleton.get_bone_pose_scale(skeleton.find_bone("Root")).x < 0.1, key + " assembles from a folded rig")
			player.play("Death",0)
			player.seek(1,true)
			test(absf(skeleton.get_bone_pose_rotation(skeleton.find_bone("Root")).get_angle()) > 0.7, key + " falls on death")
		model.queue_free()
		await process_frame
	print("BLENDER ASSETS RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
