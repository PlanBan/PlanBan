extends Node3D
class_name OrbitActor3D
## Blender skeletal clips remain the source of movement, recoil, assembly and death.
var player: AnimationPlayer
var clips: Dictionary = {}
var dying = false
var death_clock = 0.0
var attack_clock = 0.0
var deploy_clock = 0.0
var age = 0.0
var walking = false
var hostile = false
var base_scale = 0.65
var glow: MeshInstance3D
var portal: MeshInstance3D

func configure(model: Node3D, enemy: bool, scale_factor: float = 0.65, assembly: bool = true) -> void:
	hostile = enemy
	base_scale = scale_factor
	model.scale = Vector3.ONE * base_scale
	model.rotation.y = -PI / 3 if enemy else PI / 3
	add_child(model)
	player = model.find_child("AnimationPlayer", true, false)
	if player:
		for clip in player.get_animation_list():
			for key in ["Idle", "Walk", "Attack", "Deploy", "Death"]:
				if str(clip).ends_with(key):
					clips[key] = clip
					if key in ["Idle", "Walk"]: player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	glow = OrbitWorld.shape(SphereMesh.new(), Color("ff795b") if enemy else Color("64fff1"), 3.0)
	glow.scale = Vector3(0.16, 0.16, 0.16)
	glow.position = Vector3(-0.76 if enemy else 0.76, 1.13, 0)
	glow.visible = false
	add_child(glow)
	var ring = TorusMesh.new()
	ring.inner_radius = 0.65
	ring.outer_radius = 0.71
	portal = OrbitWorld.shape(ring, Color("ff886d") if enemy else Color("6aece0"), 1.2)
	portal.visible = assembly
	portal.position.y = 0.07
	add_child(portal)
	deploy_clock = 1.4 if assembly else 0.0
	play("Deploy" if assembly else "Idle")

func play(key: String) -> void:
	if player and clips.has(key): player.play(clips[key], 0.08)

func attack() -> void:
	if dying or deploy_clock > 0: return
	attack_clock = 0.72
	play("Attack")

func die() -> void:
	if dying: return
	dying = true
	death_clock = 1.65
	play("Death")
	portal.visible = false

func tick(delta: float, moving: bool, paused: bool = false) -> void:
	if player: player.speed_scale = 0.0 if paused else 1.0
	if paused: return
	age += delta
	if dying:
		death_clock -= delta
		if death_clock < 0.35: scale = Vector3.ONE * maxf(0.01, death_clock / 0.35)
		if death_clock <= 0: queue_free()
		return
	if deploy_clock > 0:
		deploy_clock -= delta
		portal.scale = Vector3.ONE * (1.0 + sin(age * 15) * 0.1)
		if deploy_clock <= 0:
			portal.visible = false
			play("Walk" if moving else "Idle")
	elif attack_clock > 0:
		attack_clock -= delta
		glow.visible = attack_clock > 0.57
		if attack_clock <= 0:
			glow.visible = false
			play("Walk" if moving else "Idle")
	elif walking != moving:
		play("Walk" if moving else "Idle")
	walking = moving
