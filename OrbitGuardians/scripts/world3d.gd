extends Node3D
class_name OrbitWorld

var game: OrbitGame
var camera: Camera3D
var stage: Node3D
var planet: Node3D
var ship_model: Node3D
var carrier: Node3D
var core_model: Node3D
var hero: OrbitActor3D
var showcase_kind = ""
var scene_key = ""
var assets: Dictionary = {}
var units: Dictionary = {}
var capsules: Dictionary = {}
var shots: Dictionary = {}
var waves_fx: Dictionary = {}
var deaths: Array[OrbitActor3D] = []
var sparks: Array[Dictionary] = []
var collecting: Array[Dictionary] = []
var hover: MeshInstance3D
var rng = RandomNumberGenerator.new()
var tiles: Dictionary = {}
var guard_nodes: Array[Node3D] = []
var tractor: MeshInstance3D
var trails: Array[Node3D] = []
var exhaust: Array[Node3D] = []

static func shape(mesh: Mesh, color: Color, emission: float = 0.0) -> MeshInstance3D:
	var object = MeshInstance3D.new()
	object.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.45
	mat.roughness = 0.5
	if emission > 0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission
	object.material_override = mat
	return object

func box(size: Vector3, pos: Vector3, color: Color, light: float = 0.0, parent: Node3D = null) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = size
	var object = shape(mesh, color, light)
	object.position = pos
	(parent if parent != null else stage).add_child(object)
	return object

func model(key: String) -> Node3D:
	if not assets.has(key): assets[key] = load("res://assets3d/%s.glb" % key)
	return assets[key].instantiate()

func _ready() -> void:
	rng.seed = 4921
	var env = WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("060e20")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("9bbadb")
	env.environment.ambient_light_energy = 0.28
	env.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.light_color = Color("fff0db")
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80
	add_child(sun)
	var rim = DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-15, 150, 0)
	rim.light_color = Color("5ca1ff")
	rim.light_energy = 0.35
	add_child(rim)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 0.1
	camera.far = 400
	camera.current = true
	add_child(camera)
	var star_mesh = SphereMesh.new()
	star_mesh.radius = 0.035
	star_mesh.height = 0.07
	star_mesh.radial_segments = 4
	star_mesh.rings = 2
	var stars = MultiMeshInstance3D.new()
	stars.multimesh = MultiMesh.new()
	stars.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	stars.multimesh.mesh = star_mesh
	stars.multimesh.instance_count = 240
	for i in range(240):
		var point = Vector3(rng.randf_range(-100, 100), rng.randf_range(-10, 80), rng.randf_range(-110, -45))
		stars.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * rng.randf_range(1, 3)), point))
	var star_mat = StandardMaterial3D.new()
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_mat.albedo_color = Color("b7d1e8")
	stars.material_override = star_mat
	add_child(stars)

func clear_stage() -> void:
	if stage:
		remove_child(stage)
		stage.queue_free()
	stage = Node3D.new()
	add_child(stage)
	units.clear()
	capsules.clear()
	shots.clear()
	waves_fx.clear()
	deaths.clear()
	sparks.clear()
	collecting.clear()
	tiles.clear()
	guard_nodes.clear()
	trails.clear()
	exhaust.clear()
	tractor = null
	hero = null
	planet = null
	ship_model = null
	carrier = null
	core_model = null
	hover = null
	showcase_kind = ""

func add_planet(sector: int, point: Vector3, radius: float) -> void:
	planet = model("planet")
	planet.position = point
	planet.scale = Vector3.ONE * radius
	var shader = load("res://shaders/planet.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("tint", Color(OrbitContent.COLORS[sector]))
	mat.set_shader_parameter("biome", sector)
	for child in planet.find_children("*", "MeshInstance3D", true, false): child.material_override = mat
	stage.add_child(planet)
	var ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = 1.28
	ring_mesh.outer_radius = 1.3
	var ring = shape(ring_mesh, Color(OrbitContent.COLORS[sector]).darkened(0.5), 0.3)
	ring.rotation.x = 0.3
	ring.rotation.z = 0.35
	planet.add_child(ring)

func setup_scene(key: String) -> void:
	clear_stage()
	scene_key = key
	key = key.get_slice(":", 0)
	if key.begins_with("battle"):
		var terrain = model("terrain_" + ("void" if game.prologue else game.mission.terrain))
		terrain.position.y = -0.24
		terrain.rotation.y = PI if game.mission.number % 2 == 0 else 0.0
		stage.add_child(terrain)
		camera.size = 13.6
		camera.position = Vector3(0, 21, 16)
		camera.look_at(Vector3(0, 1.5, 0))
		add_planet(game.mission.sector, Vector3(6, -19, -23), 3.5)
		for row in range(5):
			for col in range(9):
				var cell = Vector2i(col, row)
				var active = game.can_use_cell(cell)
				var color = Color("283f4c") if active else Color("15222d")
				if (col + row) % 2 == 0: color = color.lightened(0.045)
				var tile = box(Vector3(1.9, 0.14, 1.8), cell_position(cell), color)
				tiles[cell] = tile
				for offset in [-0.89, 0.89]: box(Vector3(0.035, 0.04, 0.55), cell_position(cell) + Vector3(offset, 0.1, 0), Color(game.mission.color).darkened(0.4), 0.5 if active else 0.0)
				if cell in game.mission.blocked:
					box(Vector3(1.1, 0.5, 0.55), cell_position(cell) + Vector3(0, 0.3, 0), Color("454959"))
			var guard = Node3D.new()
			guard.position = Vector3(-9.55, 0, (row - 2) * 1.9)
			stage.add_child(guard)
			box(Vector3(0.24, 1.7, 0.25), Vector3.ZERO + Vector3(0, 0.8, -0.6), Color("324957"), 0, guard)
			box(Vector3(0.24, 1.7, 0.25), Vector3(0, 0.8, 0.6), Color("324957"), 0, guard)
			box(Vector3(0.06, 1.3, 1.1), Vector3(0, 0.8, 0), Color("55e7da"), 1.5, guard)
			guard_nodes.append(guard)
		var hover_mesh = BoxMesh.new()
		hover_mesh.size = Vector3(1.85, 0.06, 1.75)
		hover = shape(hover_mesh, Color("45978f"), 0.6)
		stage.add_child(hover)
	elif key == "travel":
		camera.size = 12
		camera.position = Vector3(8, 5, 12)
		camera.look_at(Vector3(0, 1, 0))
		add_planet(int((game.travel_target - 1) / 10), Vector3(-7, -3, -24), 5.5)
		ship_model = model("ship")
		ship_model.scale = Vector3.ONE * 1.35
		stage.add_child(ship_model)
		add_exhaust(ship_model)
		for i in range(42):
			var trail = box(Vector3(0.025, 0.025, 2), Vector3(rng.randf_range(-12, 12), rng.randf_range(-3, 8), rng.randf_range(-20, 20)), Color("689bbb"), 0.6)
			trails.append(trail)
	elif key == "menu" or key == "hangar" or key == "map" or key == "briefing":
		camera.size = 13.5
		camera.position = Vector3(0, 7, 18)
		camera.look_at(Vector3(0, 1, 0))
		add_planet(clampi(game.level_page, 0, 4), Vector3(6, -3, -18), 4.3)
		box(Vector3(36, 0.6, 20), Vector3(0, -1.5, 0), Color("0b1b2c"))
		for i in range(6): box(Vector3(0.05, 0.02, 18), Vector3(-14 + i * 5.5, -1.17, 0), Color("326275"), 0.5)
		ship_model = model("ship")
		ship_model.position = Vector3(5.6, 1.5, -1)
		ship_model.rotation_degrees = Vector3(-9, -36, 0)
		ship_model.scale = Vector3.ONE * 1.6
		stage.add_child(ship_model)
		add_exhaust(ship_model)
	else:
		camera.size = 14.0
		camera.position = Vector3(11, 8, 19)
		camera.look_at(Vector3(0, 1, -1))
		add_planet(0 if game.story_context != "ending" else 4, Vector3(-7, -3, -24), 5.5)
		box(Vector3(14, 0.6, 9), Vector3(0, -0.7, 0), Color("182c3e"))
		for x in [-5.0, 5.0]:
			box(Vector3(0.8, 5, 0.8), Vector3(x, 1.4, -3), Color("234052"))
			box(Vector3(0.12, 3.5, 0.12), Vector3(x, 1.4, -2.53), Color("62e8ec"), 1.4)
		core_model = model("core")
		core_model.position = Vector3(0, 1.7, 0)
		stage.add_child(core_model)
		ship_model = model("ship")
		ship_model.position = Vector3(-5, 1.7, 3)
		ship_model.scale = Vector3.ONE * 0.8
		stage.add_child(ship_model)
		add_exhaust(ship_model)
		carrier = model("carrier")
		carrier.position = Vector3(6, 7, -5)
		carrier.rotation.y = PI
		stage.add_child(carrier)
		add_exhaust(carrier)
		tractor = box(Vector3(0.10, 0.10, 1), Vector3.ZERO, Color("dc696a"), 1.5)
		tractor.visible = false
		for i in range(42):
			var trail = box(Vector3(0.025, 0.025, 2), Vector3(rng.randf_range(-12, 12), rng.randf_range(-3, 8), rng.randf_range(-20, 20)), Color("689bbb"), 0.6)
			trail.visible = false
			trails.append(trail)
		for i in range(3):
			var actor = make_actor("pulse", false, 0.72, false)
			actor.position = Vector3(-3 + i * 3, 0, -2)
			actor.rotation.y = 0.2

func make_actor(kind: String, hostile: bool, scale_factor: float = 0.65, assembly: bool = true) -> OrbitActor3D:
	var actor = OrbitActor3D.new()
	stage.add_child(actor)
	actor.configure(model(kind), hostile, scale_factor, assembly)
	return actor

func cell_position(cell: Vector2i) -> Vector3:
	return Vector3((cell.x - 4) * 2.0, 0, (cell.y - 2) * 1.9)

func logical_position(point: Vector2, height: float = 0.0) -> Vector3:
	return Vector3((point.x - OrbitGame.BOARD.position.x) / OrbitGame.CELL.x * 2.0 - 9.0, height, (point.y - OrbitGame.BOARD.position.y) / OrbitGame.CELL.y * 1.9 - 4.75)

func project(point: Vector3) -> Vector2:
	return game.get_global_transform_with_canvas().affine_inverse() * camera.unproject_position(point)

func cell_from_screen(point: Vector2) -> Vector2i:
	var from = camera.project_ray_origin(game.get_global_transform_with_canvas() * point)
	var direction = camera.project_ray_normal(game.get_global_transform_with_canvas() * point)
	var hit: Variant = Plane(Vector3.UP, 0.08).intersects_ray(from, direction)
	if hit == null: return Vector2i(-1, -1)
	var cell = Vector2i(floori((hit.x + 9) / 2), floori((hit.z + 4.75) / 1.9))
	return cell if cell.x >= 0 and cell.x < 9 and cell.y >= 0 and cell.y < 5 else Vector2i(-1, -1)

func capsule_position(orb: Dictionary) -> Vector3:
	return logical_position(orb.pos, 1.55 + sin(orb.age * 2.5) * 0.12 + maxf(0, 0.7 - orb.age) * 3)

func collect_screen(point: Vector2) -> bool:
	for orb in game.orbs:
		if orb.age >= 0.5 and point.distance_to(project(capsule_position(orb))) < 31:
			collected(orb)
			return game.collect(orb.pos)
	return false

func collected(orb: Dictionary) -> void:
	if capsules.has(orb.uid):
		var object: Node3D = capsules[orb.uid]
		capsules.erase(orb.uid)
		collecting.append({"object": object, "origin": object.position, "age": 0.0})

func impact(point: Vector3, color: Color, count: int = 7) -> void:
	if sparks.size() > 120: return
	for i in range(count):
		var mesh = SphereMesh.new()
		mesh.radius = 0.045
		mesh.height = 0.09
		mesh.radial_segments = 4
		mesh.rings = 2
		var object = shape(mesh, color, 2)
		object.position = point
		stage.add_child(object)
		sparks.append({"object": object, "velocity": Vector3(rng.randf_range(-2, 2), rng.randf_range(1, 3.5), rng.randf_range(-2, 2)), "life": 0.6})

func sync_battle(delta: float) -> void:
	var paused = game.state != "battle"
	var present = {}
	for cell in game.plants:
		var bot: Dictionary = game.plants[cell]
		var uid = "bot%d" % bot.uid
		present[uid] = true
		if not units.has(uid):
			var actor = make_actor(game.robots[bot.id].kind, false, 0.65, bot.get("age", 0) < 1.4)
			actor.position = cell_position(cell) + Vector3(0, 0.09, 0)
			units[uid] = actor
			impact(actor.position, Color("7ee9df"), 8)
		var actor: OrbitActor3D = units[uid]
		if bot.flash > 0 and actor.attack_clock <= 0 and actor.deploy_clock <= 0: actor.attack()
		actor.tick(delta, false, paused)
	for enemy in game.enemies:
		var uid = "enemy%d" % enemy.id
		present[uid] = true
		if not units.has(uid): units[uid] = make_actor(game.enemy_art(enemy.kind), true, 0.85 if enemy.kind == "boss" else 0.67, enemy.get("age", 0) < 1.4)
		var actor: OrbitActor3D = units[uid]
		actor.position = logical_position(Vector2(enemy.x, game.center(Vector2i(0, enemy.row)).y), 0.1)
		if enemy.biting and actor.attack_clock <= 0: actor.attack()
		if enemy.flash > actor.get_meta("last_flash", 0.0) and not paused: impact(actor.position + Vector3(0, 1, 0), Color("ffb66e"), 3)
		actor.set_meta("last_flash", enemy.flash)
		actor.tick(delta, not enemy.biting, paused)
	for uid in units.keys():
		if not present.has(uid):
			var actor: OrbitActor3D = units[uid]
			actor.die()
			impact(actor.position + Vector3(0, 1, 0), Color("ff956e"), 12)
			deaths.append(actor)
			units.erase(uid)
	for i in range(deaths.size() - 1, -1, -1):
		if not is_instance_valid(deaths[i]): deaths.remove_at(i)
		else: deaths[i].tick(delta, false, paused)
	present.clear()
	for orb in game.orbs:
		present[orb.uid] = true
		if not capsules.has(orb.uid):
			var capsule = Node3D.new()
			var sphere = SphereMesh.new()
			sphere.radius = 0.23
			sphere.height = 0.46
			sphere.radial_segments = 12
			sphere.rings = 6
			capsule.add_child(shape(sphere, Color("84eaf5"), 2.5))
			var ring_mesh = TorusMesh.new()
			ring_mesh.inner_radius = 0.31
			ring_mesh.outer_radius = 0.34
			var ring = shape(ring_mesh, Color("38a6d0"), 1.3)
			ring.rotation.x = PI / 2
			capsule.add_child(ring)
			stage.add_child(capsule)
			capsules[orb.uid] = capsule
		var object: Node3D = capsules[orb.uid]
		object.position = capsule_position(orb)
		object.rotation.y = orb.age * 1.6
		object.scale = Vector3.ONE * clampf(orb.age * 3, 0.02, 1)
	for uid in capsules.keys():
		if not present.has(uid):
			capsules[uid].queue_free()
			capsules.erase(uid)
	present.clear()
	for bullet in game.bullets:
		present[bullet.uid] = true
		if not shots.has(bullet.uid):
			var color = Color("92d9fd") if bullet.kind == "cryo" else (Color("ffb270") if bullet.kind == "mortar" else Color("6affde"))
			shots[bullet.uid] = box(Vector3(0.55, 0.075, 0.075), Vector3.ZERO, color, 4)
		shots[bullet.uid].position = logical_position(bullet.pos, 1.1)
	for uid in shots.keys():
		if not present.has(uid):
			shots[uid].queue_free()
			shots.erase(uid)
	present.clear()
	for effect in game.effects:
		present[effect.uid] = true
		if not waves_fx.has(effect.uid):
			var object: MeshInstance3D
			if effect.get("beam", false):
				var mesh = BoxMesh.new()
				mesh.size = Vector3(18, 0.08, 0.2)
				object = shape(mesh, effect.color, 1.2)
			else:
				var mesh = TorusMesh.new()
				mesh.inner_radius = 0.96
				mesh.outer_radius = 1.0
				object = shape(mesh, effect.color, 1.2)
			object.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			object.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			stage.add_child(object)
			waves_fx[effect.uid] = object
		var object: MeshInstance3D = waves_fx[effect.uid]
		object.position = logical_position(effect.pos, 0.18 if not effect.get("beam", false) else 0.8)
		if not effect.get("beam", false):
			var radius = maxf(0.1, effect.radius / 58 * (1 - effect.life / 0.4))
			object.scale = Vector3(radius, 1, radius)
		object.material_override.albedo_color = Color(effect.color, effect.life / 0.4)
	for uid in waves_fx.keys():
		if not present.has(uid):
			waves_fx[uid].queue_free()
			waves_fx.erase(uid)
	for row in range(5): guard_nodes[row].visible = game.guards[row] and row in game.mission.lanes
	var cell = cell_from_screen(game.get_local_mouse_position())
	hover.visible = game.state == "battle" and game.can_use_cell(cell)
	if hover.visible: hover.position = cell_position(cell) + Vector3(0, 0.12, 0)
	if paused: return
	for i in range(sparks.size() - 1, -1, -1):
		var spark: Dictionary = sparks[i]
		spark.life -= delta
		spark.object.position += spark.velocity * delta
		spark.velocity.y -= 7 * delta
		spark.object.scale = Vector3.ONE * maxf(0.01, spark.life / 0.6)
		if spark.life <= 0:
			spark.object.queue_free()
			sparks.remove_at(i)
	for i in range(collecting.size() - 1, -1, -1):
		var item: Dictionary = collecting[i]
		item.age += delta
		item.object.position = item.origin + Vector3(1, 5, -2) * item.age
		item.object.scale = Vector3.ONE * maxf(0.01, 1 - item.age * 2)
		if item.age > 0.5:
			item.object.queue_free()
			collecting.remove_at(i)

func _process(delta: float) -> void:
	if not game or not is_instance_valid(game) or not game.view: return
	var battle = game.state in ["battle", "pause", "victory", "defeat"] or (game.state in ["save", "load", "settings"] and game.return_state in ["battle", "pause"])
	var key = ("battle%d_%s_%s" % [game.mission.number, game.prologue, game.battle_generation]) if battle else ("story" if game.state in ["dialogue", "cinematic", "travel"] else (game.state if game.state in ["menu", "hangar", "map", "briefing"] else "menu"))
	if game.state == "travel": key = "travel:%d" % int((game.travel_target - 1) / 10)
	if key in ["menu", "map", "briefing"]: key += ":%d" % game.level_page
	if key != scene_key: setup_scene(key)
	if battle:
		sync_battle(delta)
		return
	if planet: planet.rotation.y += delta * 0.015
	for flame in exhaust: flame.scale = Vector3.ONE * (0.8 + sin(game.ui_time * 19 + flame.position.x) * 0.12)
	if game.state == "hangar":
		if ship_model: ship_model.visible = false
		var kind: String = game.robots[game.focus_robot].kind
		if kind != showcase_kind:
			if hero: hero.queue_free()
			hero = make_actor(kind, false, 1.45, false)
			hero.position = Vector3(8.8, -0.4, -1)
			showcase_kind = kind
		if hero:
			hero.rotation.y = game.ui_time * 0.3
			hero.tick(delta, false)
	elif ship_model and game.state in ["menu", "map", "briefing", "settings", "save", "load", "new_confirm"]:
		ship_model.position.y = 1.5 + sin(game.ui_time) * 0.15
		ship_model.rotation.y = -0.63 + sin(game.ui_time * 0.25) * 0.1
	elif game.state == "travel":
		for trail in trails:
			trail.visible = true
			trail.position.z = wrapf(trail.position.z + delta * 28, -22, 22)
		if core_model: core_model.visible = false
		if carrier: carrier.visible = false
		ship_model.position = Vector3(sin(game.scene_clock) * 0.2, 2, 0)
		ship_model.scale = Vector3.ONE * 1.35
		camera.position = Vector3(8, 5, 12)
		camera.look_at(Vector3(0, 1, 0))
	elif game.state == "cinematic":
		var t = game.scene_clock
		for actor in stage.get_children():
			if actor is OrbitActor3D and t > 2 and not actor.dying: actor.die()
		tractor.visible = t > 1 and t < 6.8
		if tractor.visible:
			var end = carrier.position + Vector3(0, -0.25, 0)
			tractor.position = (end + core_model.position) * 0.5
			tractor.scale.z = maxf(0.05, end.distance_to(core_model.position))
			if end.distance_to(core_model.position) > 0.1: tractor.look_at(core_model.position)
		var amount = smoothstep(1.5, 6, t)
		core_model.position = Vector3(0, 1.7, 0).lerp(Vector3(6, 6.6, -5), amount)
		core_model.rotation.y = t * 1.6
		carrier.position.x = 6 + pow(maxf(0, t - 7), 2) * 0.5
		core_model.visible = t < 7
		ship_model.position = Vector3(-5, 1.7, 3).lerp(Vector3(9, 5, -8), smoothstep(8, 14, t))
		camera.position = Vector3(11 - t * 0.3, 7.5, 18 - t * 0.35)
		camera.look_at(core_model.position if t < 7 else ship_model.position)
		if int(t * 30) % 5 == 0: impact(Vector3(rng.randf_range(-5, 5), 0.2, rng.randf_range(-2, 2)), Color("ff7258"), 2)
	elif game.state == "dialogue":
		var line = game.story_line()
		carrier.visible = line.scene == "raid"
		core_model.visible = line.scene in ["home", "core", "raid"]
		core_model.rotation.y = game.ui_time * 0.4
		carrier.position.y = 7 + sin(game.ui_time * 0.6) * 0.25
		camera.position = Vector3(11, 7.2, 17) if line.scene in ["home", "raid", "core"] else Vector3(7, 5, 13)
		camera.look_at(Vector3(0, 1.4, 0))
	for actor in stage.get_children():
		if actor is OrbitActor3D: actor.tick(delta, false)
	for i in range(sparks.size() - 1, -1, -1):
		sparks[i].life -= delta
		sparks[i].object.position += sparks[i].velocity * delta
		if sparks[i].life <= 0:
			sparks[i].object.queue_free()
			sparks.remove_at(i)


func add_exhaust(parent: Node3D) -> void:
	for x in [-0.73, 0.73]:
		var mesh = CylinderMesh.new()
		mesh.top_radius = 0.22
		mesh.bottom_radius = 0.015
		mesh.height = 1.6
		mesh.radial_segments = 12
		var flame = shape(mesh, Color("42cff0") if parent == ship_model else Color("ff584e"), 2.5)
		flame.position = Vector3(x, -0.05, -2.9)
		flame.rotation.x = PI / 2
		parent.add_child(flame)
		exhaust.append(flame)
