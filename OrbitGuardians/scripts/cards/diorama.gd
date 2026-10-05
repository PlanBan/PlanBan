extends Node3D
class_name AstraDiorama
## A physical miniature world; its sockets and projected touch positions share one source of truth.
var world: AstraTable
var game: AstraGame
var tokens: Dictionary = {}
var player: Node3D
var player_target = Vector3.ZERO
var player_home = Vector3.ZERO
var clock = 0.0
var last_selection = ""
var path_root: Node3D
var coordinates: Dictionary = {}
var token_transforms: Array = []
const CYAN = Color("2de3ff")
const AMBER = Color("ff7929")
const PALE = Color("b9ae8e")
const ICONS = {"battle":"swords","elite":"skull","boss":"skull","event":"question","reward":"cards","upgrade":"wrench","rest":"fire","shop":"chest","remove":"recycle","planet":"planet"}
func setup(parent_world: AstraTable, controller: AstraGame, act: int, active: bool = true) -> void:
 world = parent_world; game = controller
 coordinates = JSON.parse_string(FileAccess.get_file_as_string("res://assets3d/diorama/manifest.json")).route_positions
 var terrain = world.model("res://assets3d/diorama/world_%d.glb" % act); add_child(terrain)
 animate_water(terrain,act)
 if not active: return
 path_root = Node3D.new(); add_child(path_root)
 for entry in game.run.data.map:
  var root = Node3D.new(); add_child(root); root.position = node_position(entry.id)
  token_transforms.append(Transform3D(Basis.IDENTITY,root.position))
  if entry.kind in ["elite","boss"]:
   var gate = world.model("res://assets3d/diorama/archon_gate.glb"); root.add_child(gate)
   gate.scale = Vector3.ONE*(1.5 if entry.kind == "boss" else .85)
   # Keep the readable glyph on the front lip of the reactor crown.
  var decal = MeshInstance3D.new(); var quad = QuadMesh.new(); quad.size = Vector2(.57,.57)
  decal.mesh = quad; root.add_child(decal); decal.rotation.x = -PI/2; decal.position.y = .13
  if entry.kind in ["elite","boss"]: decal.position.z = .47; decal.scale *= .7
  var ink = StandardMaterial3D.new(); ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; ink.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  ink.albedo_texture = load("res://assets3d/diorama/icons/%s.svg" % ICONS[entry.kind]); ink.albedo_color = Color("eee5cc"); decal.material_override = ink
  var ring = MeshInstance3D.new(); var torus = TorusMesh.new(); torus.inner_radius = .472; torus.outer_radius = .494; torus.rings = 32; torus.ring_segments = 6
  ring.mesh = torus; root.add_child(ring); ring.position.y = .12
  var mat = world.material(PALE,.2); mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; ring.material_override = mat
  var halo = glow(root,Vector3(0,.105,0),1.65,CYAN,.45)
  tokens[entry.id] = {"root":root,"ring":ring,"material":mat,"halo":halo,"entry":entry}
  world.map_nodes[entry.id] = {"mesh":root,"node":entry,"point":world.project(to_global(root.position+Vector3(0,.12,0)))}
 batch_tokens()
 player = world.model("res://assets3d/diorama/explorer.glb"); add_child(player); player.scale = Vector3.ONE*.80
 world.animate_model(player,"Idle")
 player_home = node_position(game.run.data.current) if game.run.data.current in coordinates else Vector3(0,.43,6.02)
 if game.run.data.current in coordinates: player_home += Vector3(0,.08,.64)
 player_target = player_home; player.position = player_home
 glow(self,player_home-Vector3(0,.04,0),1.55,CYAN,.85)
 for i in range(4):
  var light = OmniLight3D.new(); add_child(light); light.position = Vector3(-4.8 if i%2 == 0 else 4.8,1.45,-4.5+i*3.3)
  light.light_color = Color("ff742d"); light.light_energy = .45; light.omni_range = 2.9
 var boss_light = OmniLight3D.new(); add_child(boss_light); boss_light.position = node_position("6_1")+Vector3(0,1,0)
 boss_light.light_color = AMBER; boss_light.light_energy = 1.2; boss_light.omni_range = 3.5
 rebuild_paths()
func batch_tokens() -> void:
 var source = world.model("res://assets3d/diorama/route_token.glb")
 var meshes = source.find_children("*","MeshInstance3D",true,false)
 for part in meshes:
  var multimesh = MultiMesh.new(); multimesh.transform_format = MultiMesh.TRANSFORM_3D; multimesh.mesh = part.mesh
  multimesh.instance_count = token_transforms.size()
  var local: Transform3D = part.transform
  var ancestor = part.get_parent()
  while ancestor != source: local = ancestor.transform*local; ancestor = ancestor.get_parent()
  for i in range(token_transforms.size()): multimesh.set_instance_transform(i,token_transforms[i]*local)
  var instance = MultiMeshInstance3D.new(); instance.multimesh = multimesh; add_child(instance)
 source.free()
func node_position(id: String) -> Vector3:
 var p: Array = coordinates.get(id,[0,0,.5])
 return Vector3(float(p[0]),float(p[2]),-float(p[1]))
func glow(parent: Node3D, pos: Vector3, size_value: float, color: Color, strength: float) -> MeshInstance3D:
 var mesh = MeshInstance3D.new(); var quad = QuadMesh.new(); quad.size = Vector2.ONE*size_value; mesh.mesh = quad
 var shader = ShaderMaterial.new(); shader.shader = load("res://shaders/route_glow.gdshader"); shader.set_shader_parameter("color",color); shader.set_shader_parameter("strength",strength)
 mesh.material_override = shader; mesh.position = pos; mesh.rotation.x = -PI/2; parent.add_child(mesh); return mesh
func animate_water(node: Node, act: int) -> void:
 if node is MeshInstance3D and node.mesh != null:
  for surface in range(node.mesh.get_surface_count()):
   var mat = node.mesh.surface_get_material(surface)
   if mat != null and mat.resource_name.contains("animated water"):
    var water = ShaderMaterial.new(); water.shader = load("res://shaders/diorama_water.gdshader")
    water.set_shader_parameter("tint",[Color("087588"),Color("1297c4"),Color("ff3703"),Color("078b86"),Color("7624d9")][act]); water.set_shader_parameter("hot",1.0 if act in [2,4] else 0.0)
    node.set_surface_override_material(surface,water)
 for child in node.get_children(): animate_water(child,act)
func rebuild_paths() -> void:
 for child in path_root.get_children(): child.queue_free()
 var groups = {"cyan":[],"future":[],"danger":[],"past":[]}
 var available = game.run.available_nodes(); var visited: Array = game.run.data.visited
 for entry in game.run.data.map:
  for id in entry.links:
   var color = "future"
   if entry.id in visited and id in visited: color = "cyan"
   elif entry.id == game.run.data.current and id in available: color = "cyan"
   elif int(entry.depth) <= int(game.run.data.depth): color = "past"
   elif tokens[id].entry.kind in ["boss","elite"]: color = "danger"
   append_dashes(groups[color],node_position(entry.id),node_position(id))
 if game.run.data.current == "": append_dashes(groups.cyan,Vector3(0,.43,6.0),node_position("0_1"))
 for key in groups:
  if groups[key].is_empty(): continue
  var multimesh = MultiMesh.new(); multimesh.transform_format = MultiMesh.TRANSFORM_3D
  var box = BoxMesh.new(); box.size = Vector3(.12,.035,.24); box.material = world.material({"cyan":CYAN,"future":PALE.darkened(.22),"danger":AMBER,"past":Color("353a35")}[key],1.1 if key == "cyan" else .05)
  multimesh.mesh = box; multimesh.instance_count = groups[key].size()
  for i in range(groups[key].size()): multimesh.set_instance_transform(i,groups[key][i])
  var instance = MultiMeshInstance3D.new(); instance.multimesh = multimesh; path_root.add_child(instance)
func append_dashes(target: Array, a: Vector3, b: Vector3) -> void:
 var distance = a.distance_to(b); var count = maxi(1,int(distance/.43))
 for i in range(1,count):
  var t = float(i)/count
  if t*distance < .49 or (1-t)*distance < .49: continue
  var pos = a.lerp(b,t)+Vector3(0,.04,0)
  var y = -pos.z
  var terrain = .38+.10*sin(pos.x*2.7+y*.8)+.075*cos(y*2.4-pos.x)
  pos.y = maxf(pos.y,terrain+.15)
  var basis = Basis.looking_at((b-a).normalized(),Vector3.UP)
  target.append(Transform3D(basis,pos))
func travel_to(id: String, duration: float) -> void:
 if player == null or id not in tokens: return
 var target = node_position(id)+Vector3(0,.15,.12)
 var tween = create_tween(); tween.tween_property(self,"player_target",target,duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
 world.animate_model(player,"Walk")
 player.look_at(to_global(target),Vector3.UP,true)
func scroll(amount: float) -> void:
 position.z = clampf(position.z+amount*.007,-.45,.45)
func _process(delta: float) -> void:
 if game == null or game.quitting or world.diorama != self: return
 clock += delta
 if player == null: return
 player.position = player_target+Vector3(0,sin(clock*2.2)*.025,0)
 var moving = player_target.distance_to(player_home) > .08
 player.rotation.z = sin(clock*(14 if moving else 2))*(.04 if moving else .012)
 var available = game.run.available_nodes()
 for id in tokens:
  var item: Dictionary = tokens[id]
  var lit = id in available; var visited = id in game.run.data.visited
  var selected = game.selected_node == id and lit
  var danger = item.entry.kind in ["boss","elite"]
  var color = CYAN if lit or visited else (AMBER if danger else PALE.darkened(.38))
  item.material.albedo_color = color; item.material.emission = color; item.material.emission_energy_multiplier = 1.6 if lit else .2
  item.halo.visible = lit or visited or danger
  item.halo.material_override.set_shader_parameter("color",color)
  item.halo.material_override.set_shader_parameter("strength",(.9+sin(clock*3)*.15) if selected else (.38 if lit or danger else .15))
  world.map_nodes[id].point = world.project(to_global(item.root.position+Vector3(0,.12,0)))
