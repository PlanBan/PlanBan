extends Node2D
class_name OrbitBackdrop

var game: OrbitGame
var planet: ColorRect
var shader_material: ShaderMaterial
var stars: Array[Vector3] = []

func _ready() -> void:
	var random = RandomNumberGenerator.new()
	random.seed = 17422
	for i in range(180): stars.append(Vector3(random.randf_range(-80, 1520), random.randf_range(0, 900), random.randf_range(0.4, 1.8)))
	planet = ColorRect.new()
	planet.size = Vector2(704, 704)
	planet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://shaders/planet.gdshader")
	planet.material = shader_material
	add_child(planet)

func _process(_delta: float) -> void:
	var sector: int = game.level_page if game.state == "map" else game.mission.sector
	if game.state == "travel": sector = int((game.travel_target - 1) / 10)
	shader_material.set_shader_parameter("biome", sector)
	shader_material.set_shader_parameter("tint", Color(OrbitContent.COLORS[sector]))
	shader_material.set_shader_parameter("clock", game.ui_time)
	planet.position = Vector2(733, 26 + sin(game.ui_time * 0.2) * 5)
	planet.modulate.a = 0.45 if game.state in ["battle", "pause", "victory", "defeat"] else 0.95
	queue_redraw()

func _draw() -> void:
	for i in range(90):
		var t = float(i) / 90.0
		draw_rect(Rect2(-80, i * 10, 1600, 10.1), Color("102035").lerp(Color("050b17"), t))
	for point in stars:
		var x = wrapf(point.x - game.ui_time * point.z * 2.0, -80, 1520)
		draw_circle(Vector2(x, point.y), point.z, Color(0.65, 0.81, 1.0, 0.28 + 0.24 * sin(game.ui_time * 0.5 + point.x)))
	var phase = fmod(game.ui_time, 14.0)
	if phase < 1.2:
		var head = Vector2(920 - phase * 440, 30 + phase * 150)
		draw_line(head, head + Vector2(80, -27), Color(0.5, 0.85, 1.0, (1.0 - phase / 1.2) * 0.45), 1.5)
