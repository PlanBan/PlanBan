extends Node3D
class_name AstraTable
## World-space card plates, portrait composition, map etched onto the physical table.
var game: Node
var camera: Camera3D
var cards: Dictionary = {}
var map_nodes: Dictionary = {}
var map_root: Node3D
var table_model: Node3D
var props: Node3D
var planet: MeshInstance3D
var lamp: OmniLight3D
var clock = 0.0
var map_scroll = 0.0
var scene_signature = ""
var scenes: Dictionary = {}
var transient: Array = []
var masks: Array = []
var ambience: Node3D
var showcase: Node3D
var stage_models: Dictionary = {}
var stage_clock = 0.0
var biome_index = -1
var diorama: AstraDiorama
var room: Node3D
var arena: Node3D
const SCREEN = Vector2(720,1280)
func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
 var mat = StandardMaterial3D.new(); mat.albedo_color = color; mat.metallic = 0.7; mat.roughness = 0.44
 if glow > 0: mat.emission_enabled = true; mat.emission = color; mat.emission_energy_multiplier = glow
 return mat
func box(parent: Node3D, pos: Vector3, size_value: Vector3, mat: Material) -> MeshInstance3D:
 var mesh = MeshInstance3D.new(); var shape = BoxMesh.new(); shape.size = size_value
 mesh.mesh = shape; mesh.material_override = mat; parent.add_child(mesh); mesh.position = pos; return mesh
func sphere(parent: Node3D, pos: Vector3, radius: float, mat: Material) -> MeshInstance3D:
 var mesh = MeshInstance3D.new(); var shape = SphereMesh.new(); shape.radius = radius; shape.height = radius * 2; shape.radial_segments = 20; shape.rings = 12
 mesh.mesh = shape; mesh.material_override = mat; parent.add_child(mesh); mesh.position = pos; return mesh
func model(path: String) -> Node3D:
 if not scenes.has(path): scenes[path] = load(path)
 return scenes[path].instantiate()
func animate_model(root: Node, clip: String) -> void:
 for player in root.find_children("*","AnimationPlayer",true,false):
  for name in player.get_animation_list():
   if name.to_lower().ends_with(clip.to_lower()):
    if clip in ["Idle","Walk"]: player.get_animation(name).loop_mode = Animation.LOOP_LINEAR
    player.play(name,.12)
    if clip not in ["Idle","Walk"]:
     for idle in player.get_animation_list():
      if idle.to_lower().ends_with("idle"): player.get_animation(idle).loop_mode = Animation.LOOP_LINEAR; player.queue(idle)
    return
func _ready() -> void:
 var environment = WorldEnvironment.new(); var env = Environment.new()
 env.background_mode = Environment.BG_COLOR; env.background_color = Color("050b12")
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color("91abc1"); env.ambient_light_energy = 0.40
 var sky = Sky.new(); var sky_mat = ProceduralSkyMaterial.new()
 sky_mat.sky_top_color = Color("14283e"); sky_mat.sky_horizon_color = Color("687881"); sky_mat.ground_horizon_color = Color("635347"); sky_mat.ground_bottom_color = Color("101922")
 sky_mat.sky_energy_multiplier = .55; sky_mat.ground_energy_multiplier = .45
 sky.sky_material = sky_mat; sky.radiance_size = Sky.RADIANCE_SIZE_128; env.sky = sky; env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
 env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 environment.environment = env; add_child(environment)
 camera = Camera3D.new(); add_child(camera); camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.size = 19.7
 camera.position = Vector3(0,18,11.4); camera.look_at(Vector3(0,0,0)); camera.current = true; camera.far = 100
 var key = SpotLight3D.new(); add_child(key); key.position = Vector3(-4,12,4); key.look_at(Vector3(0,0,0)); key.light_color = Color("ffdcac"); key.light_energy = 3.8; key.spot_range = 28; key.spot_angle = 57; key.shadow_enabled = true; key.shadow_bias = 0.25; key.shadow_normal_bias = 2.5
 var fill = OmniLight3D.new(); add_child(fill); fill.position = Vector3(4,5,-3); fill.light_color = Color("52b8e4"); fill.light_energy = 1.25; fill.omni_range = 12
 lamp = OmniLight3D.new(); add_child(lamp); lamp.position = Vector3(-4,2,5); lamp.light_color = Color("ff9648"); lamp.light_energy = 0.9; lamp.omni_range = 8
 table_model = model("res://assets3d/tabletop/spark_table.glb"); add_child(table_model)
 room = model("res://assets3d/diorama/command_desk.glb"); add_child(room)
 props = Node3D.new(); add_child(props)
 planet = sphere(props,Vector3(0,3,-9),2.2,material(Color("518973")))
 planet.material_override = ShaderMaterial.new(); planet.material_override.shader = load("res://shaders/planet.gdshader")
 map_root = Node3D.new(); add_child(map_root)
 ambience = Node3D.new(); add_child(ambience)
 showcase = Node3D.new(); add_child(showcase)
 arena = Node3D.new(); add_child(arena)
 set_process(true)
func project(pos: Vector3) -> Vector2:
 return game.view.get_global_transform_with_canvas().affine_inverse()*camera.unproject_position(pos)
func position_for(point: Vector2, height: float = 0.3) -> Vector3:
 var pixel = game.view.get_global_transform_with_canvas()*point
 var origin = camera.project_ray_origin(pixel); var direction = camera.project_ray_normal(pixel)
 var hit = Plane(Vector3.UP,height).intersects_ray(origin,direction)
 return hit if hit != null else Vector3.ZERO
func slot_point(side: String, lane: int) -> Vector2:
 return Vector2(120 + lane * 160, 490 if side == "enemy" else 730)
func route_point(node: Dictionary) -> Vector2:
 if diorama != null and is_instance_valid(diorama): return project(diorama.to_global(diorama.node_position(node.id)+Vector3(0,.12,0)))
 return Vector2(135 + int(node.col)*225, 908 - int(node.depth)*84)
func make_card(key: String, entry: Dictionary, hostile: bool) -> Dictionary:
 var card_node = Node3D.new(); add_child(card_node)
 box(card_node,Vector3.ZERO,Vector3(1.86,0.10,2.66),material(Color("1c2220") if hostile else Color("756e54")))
 var outline = box(card_node,Vector3(0,-0.017,0),Vector3(1.94,0.045,2.74),material(Color("e2774e") if hostile else Color("53c7b5"),0.45))
 var viewport = SubViewport.new(); viewport.size = Vector2i(300,430); viewport.transparent_bg = false; viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
 card_node.add_child(viewport)
 var face = AstraCardFace.new(); face.card = entry.duplicate(true); face.language = game.language(); face.hostile = hostile; viewport.add_child(face)
 var mesh = MeshInstance3D.new(); var quad = QuadMesh.new(); quad.size = Vector2(1.79,2.57); mesh.mesh = quad
 var face_mat = StandardMaterial3D.new(); face_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; face_mat.albedo_texture = viewport.get_texture(); face_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS; mesh.material_override = face_mat
 card_node.add_child(mesh); mesh.position.y = 0.065; mesh.rotation.x = -PI/2
 var record = {"node":card_node,"face":face,"viewport":viewport,"outline":outline,"entry":entry.duplicate(true),"target":Vector3.ZERO,"point":Vector2.ZERO,"polygon":PackedVector2Array(),"scale":1.0,"rot":0.0,"side":"","lane":-1,"hand":-1,"key":key,"mini":null,"dying":false,"life":0.0,"language":game.language()}
 cards[key] = record
 return record
func bind_card(key: String, entry: Dictionary, point: Vector2, scale_value: float, angle: float, side: String, lane: int, hand: int = -1) -> void:
 var fresh = not cards.has(key)
 var record = make_card(key,entry,side == "enemy") if fresh else cards[key]
 if record.dying: record.life = 0.0
 record.dying = false
 record.point = point; record.target = position_for(point,0.39 if hand < 0 else 0.64)
 record.scale = scale_value; record.rot = angle; record.side = side; record.lane = lane; record.hand = hand
 if fresh:
  record.node.position = record.target + Vector3(0,2.8,0.8); record.node.scale = Vector3.ONE * scale_value
 if record.entry != entry or record.language != game.language():
  if record.mini != null and record.entry.art != entry.art:
   record.mini.queue_free(); record.mini = null
  record.entry = entry.duplicate(true); record.face.card = entry.duplicate(true); record.face.language = game.language(); record.language = game.language(); record.face.queue_redraw(); record.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
 record.outline.visible = (hand >= 0 and hand == game.selected) or game.drag_key == key
 if side in ["friendly","enemy"] and record.mini == null and entry.hp > 0:
  var path = "res://assets3d/diorama/explorer.glb" if entry.art == "pulse" else "res://assets3d/tabletop/card_%s.glb" % entry.art
  if ResourceLoader.exists(path):
   record.mini = model(path); record.node.add_child(record.mini); record.mini.scale = Vector3.ONE*0.01; record.mini.position = Vector3(0,0.12,-0.38); record.mini.rotation.y = PI if side == "enemy" else 0
   animate_model(record.mini,"Deploy")
 masks.append(key)
func sync_cards() -> void:
 masks.clear()
 var screen: String = game.screen
 if screen in ["battle","pause"] and not game.run.battle.data.is_empty():
  var battle: Dictionary = game.run.battle.data
  for side in ["enemy","friendly"]:
   for lane in range(4):
    if battle[side][lane] != null:
     var entry: Dictionary = battle[side][lane]
     bind_card(("e" if side == "enemy" else "c")+str(entry.uid),entry,slot_point(side,lane),1.17,0,side,lane)
  var hand: Array = battle.hand
  var spacing = minf(114.0,500.0 / maxf(1,hand.size()-1))
  for index in range(hand.size()):
   var entry = AstraCards.card(hand[index].id,int(hand[index].upgrade)); entry.uid = hand[index].uid
   var relative = index - (hand.size()-1)/2.0
   var point = Vector2(360+relative*spacing,1049+absf(relative)*11)
   if index == game.selected: point.y -= 74
   if game.drag_key == "c"+str(entry.uid): point = game.pointer - Vector2(0,75)
   bind_card("c"+str(entry.uid),entry,point,1.06,relative*0.055,"hand",-1,index)
 elif screen in ["reward","shop"]:
  var offers: Array = game.run.data.reward if screen == "reward" else game.run.data.stock
  for index in range(offers.size()):
   if offers[index] == "": continue
   var entry = AstraCards.card(offers[index]); entry.uid = 9000 + index
   bind_card("r%d" % index,entry,Vector2(140+index*220,570),1.60,0,"offer",index)
 elif screen == "inspect":
  var entry: Dictionary = game.inspect_entry.duplicate(true); entry.uid = 99000
  bind_card("inspect",entry,Vector2(360,587),2.9,0,"inspect",-1)
 elif screen in ["upgrade","remove","deck","collection"]:
  var entries: Array = game.display_entries()
  for index in range(mini(6,entries.size()-game.page*6)):
   var entry = entries[game.page*6+index]
   var value = AstraCards.card(entry.id,int(entry.get("upgrade",0))); value.uid = entry.uid
   bind_card("d%d" % entry.uid,value,Vector2(140+(index%3)*220,465+int(index/3)*315),1.32,0,"browse",game.page*6+index)
 for key in cards.keys():
  if key not in masks and not cards[key].dying:
   cards[key].dying = true; cards[key].life = 0.6
func set_stage() -> void:
 var act = int(game.run.data.get("act",0))
 var signature = "%s/%d/%s/%d" % [game.screen,act,game.language(),int(game.run.data.get("hull",0))]
 if signature == scene_signature: return
 scene_signature = signature
 stage_clock = 0
 make_ambience(act)
 make_showcase()
 for child in map_root.get_children(): child.queue_free()
 diorama = null
 map_nodes.clear()
 planet.visible = game.screen in ["menu","new","intro","travel","ending"]
 camera.size = 18.4 if game.screen in ["map","overview"] else 19.7
 room.visible = true
 table_model.visible = false
 for child in arena.get_children(): child.queue_free()
 if game.screen in ["battle","pause"]: make_arena()
 if planet.material_override is ShaderMaterial:
  planet.material_override.set_shader_parameter("biome",act)
  planet.material_override.set_shader_parameter("tint",AstraCards.COLORS[act])
 if game.screen in ["map","overview","menu","new","intro","travel","ending"]:
  diorama = AstraDiorama.new(); map_root.add_child(diorama)
  diorama.setup(self,game,act,game.screen == "map")
  if game.screen != "map": diorama.rotation.y = -.10; diorama.position.y = -.12
 if game.screen == "map":
  var special = AstraCards.card(["verdant","frost","ember","storm","echo"][act])
  var preview = model("res://assets3d/diorama/explorer.glb" if special.art == "pulse" else "res://assets3d/tabletop/card_%s.glb" % special.art); showcase.add_child(preview)
  preview.position = position_for(Vector2(603,178),1.8); preview.scale = Vector3.ONE*(.9 if special.art == "pulse" else .60); stage_models.reward_preview = preview
  animate_model(preview,"Idle")
func rebuild_links() -> void:
 for child in map_root.get_children():
  if child.name.begins_with("RouteLink"): child.queue_free()
 var edges = material(Color("4e5945"))
 for node in game.run.data.map:
  for next_id in node.links:
   if not map_nodes.has(next_id): continue
   var a: Vector3 = position_for(route_point(node),0.315)
   var b: Vector3 = position_for(route_point(map_nodes[next_id].node),0.315)
   var line = box(map_root,(a+b)/2,Vector3(0.045,0.025,(a-b).length()),edges); line.name = "RouteLink"; line.look_at(b,Vector3.UP)
func scroll_map(amount: float) -> void:
 if game.screen != "map": return
 if diorama != null: diorama.scroll(amount)
func pick_card(point: Vector2) -> Dictionary:
 # Selected card takes priority where the fanned hand overlaps.
 if game.selected >= 0:
  for value in cards.values():
   if value.hand == game.selected and not value.dying and Geometry2D.is_point_in_polygon(point,value.polygon): return value
 var values = cards.values(); values.reverse()
 for value in values:
  if not value.dying and Geometry2D.is_point_in_polygon(point,value.polygon): return value
 return {}
func pick_slot(point: Vector2) -> Dictionary:
 for side in ["friendly","enemy"]:
  for lane in range(4):
   if Rect2(slot_point(side,lane)-Vector2(75,100),Vector2(150,200)).has_point(point): return {"side":side,"lane":lane}
 return {}
func feedback(events: Array) -> void:
 for event in events:
  var key = ("e" if event.get("side","") == "enemy" else "c")+str(event.get("uid",-1))
  if event.kind == "attack" and cards.has(key):
   if cards[key].mini != null: animate_model(cards[key].mini,"Attack")
   var node: Node3D = cards[key].node
   var target: Vector3 = cards[key].target
   var tween = create_tween(); tween.tween_property(node,"position",target+Vector3(0,0.48,-0.75 if event.side == "friendly" else 0.75),0.13).set_trans(Tween.TRANS_QUAD); tween.tween_property(node,"position",target,0.22)
   cards[key].life = 0.36
  if event.kind == "death" and cards.has(key) and cards[key].mini != null: animate_model(cards[key].mini,"Death")
  if event.kind in ["deploy","hit","death","ability","core"]:
   var pos = slot_point(event.get("side","friendly"),clampi(int(event.get("lane",1)),0,3))
   if event.kind == "core": pos = Vector2(360,229 if event.side == "enemy" else 886)
   for i in range(6):
    var spark = sphere(self,position_for(pos,0.8),0.035,material(Color("f6ae62") if event.get("side","") == "enemy" else Color("65d9c4"),1.4))
    transient.append({"node":spark,"velocity":Vector3(sin(i*4.7)*1.7,1.6,cos(i*4.7)*1.7),"life":0.5})
func _process(delta: float) -> void:
 if game.quitting: return
 clock += delta; stage_clock += delta
 animate_showcase(delta)
 set_stage(); sync_cards()
 ambience.visible = game.screen not in ["map","overview","menu","new","intro","travel","ending"]
 lamp.light_energy = 0.85 + sin(clock*4.1)*0.07 + sin(clock*23)*0.02
 planet.rotation.y += delta*0.025
 if stage_models.has("reward_preview"): stage_models.reward_preview.rotation.y = sin(clock*.55)*.28
 for key in cards.keys():
  var value: Dictionary = cards[key]
  var node: Node3D = value.node
  value.life -= delta
  if value.dying:
   node.rotation.z = lerpf(node.rotation.z,-0.5,delta*4); node.position.y = lerpf(node.position.y,-0.25,delta*4); node.scale *= maxf(0.01,1-delta*2.5)
   if value.life <= 0: node.queue_free(); cards.erase(key); continue
  elif value.life <= 0:
   var target: Vector3 = value.target
   if value.hand >= 0 and value.hand == game.selected: target.y += 0.4
   node.position = node.position.lerp(target,minf(1,delta*11)); node.rotation.y = lerpf(node.rotation.y,value.rot,minf(1,delta*9)); node.scale = node.scale.lerp(Vector3.ONE*value.scale,minf(1,delta*9))
  if value.mini != null:
   value.mini.scale = value.mini.scale.lerp(Vector3.ONE*(.46 if value.entry.art == "pulse" else .30),minf(1,delta*4))
   value.mini.position.y = 0.14+sin(clock*2+float(value.entry.uid))*0.025
   value.mini.rotation.y = (PI if value.side == "enemy" else 0)+sin(clock*.65)*.08
  var polygon = PackedVector2Array()
  for point in [Vector3(-.97,.12,-1.37),Vector3(.97,.12,-1.37),Vector3(.97,.12,1.37),Vector3(-.97,.12,1.37)]: polygon.append(project(node.to_global(point)))
  value.polygon = polygon
 for i in range(transient.size()-1,-1,-1):
  var value: Dictionary = transient[i]; value.life -= delta
  value.node.position += value.velocity*delta; value.velocity.y -= delta*6
  if value.life <= 0: value.node.queue_free(); transient.remove_at(i)

func beam(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material) -> MeshInstance3D:
 var node = box(parent,(a+b)/2,Vector3(radius,radius,(a-b).length()),mat)
 node.look_at(b,Vector3.UP)
 return node
func make_arena() -> void:
 var steel = material(Color("182b34")); steel.roughness = .65
 box(arena,Vector3(0,.16,.1),Vector3(9.6,.12,13.0),steel)
 for side in ["friendly","enemy"]:
  var cyan = material(Color("38b5d4") if side == "friendly" else Color("c65b38"),.4)
  var recess = material(Color("0a151e")); recess.metallic = .45
  for lane in range(4):
   var center = position_for(slot_point(side,lane),.26)
   box(arena,center,Vector3(2.24,.06,3.1),recess)
   for dx in [-1.06,1.06]:
    for dz in [-1.42,1.42]:
     box(arena,center+Vector3(dx,.05,dz),Vector3(.13,.025,.21),cyan)
   for dz in [-1.50,1.50]: box(arena,center+Vector3(0,.036,dz),Vector3(1.87,.025,.023),material(Color("566872")))
 var center = position_for(Vector2(360,611),.24)
 for x in range(-4,5): box(arena,center+Vector3(x,.005,0),Vector3(.28,.016,.032),material(Color("506472")))
func make_ambience(act: int) -> void:
 if act == biome_index: return
 biome_index = act
 for child in ambience.get_children(): child.queue_free()
 var color = AstraCards.COLORS[act]
 var bright = material(color,0.65)
 var muted = material(color.darkened(0.6))
 # The same terrain library frames combat, with a recessed central board for readable cards.
 var landscape = model("res://assets3d/diorama/world_%d.glb" % act); ambience.add_child(landscape)
 landscape.position.y = -.70; landscape.scale.x = 1.32
 for child in landscape.get_children():
  if child is MeshInstance3D and not child.name.begins_with("Water"): child.visible = false
 for side in [-1,1]:
  for i in range(5):
   var pos = Vector3(side*5.05,0.23,-4+i*1.75)
   match act:
    0:
     var a = pos+Vector3(0,0.07,-.6); var b = pos+Vector3(side*.24,.22,.6)
     beam(ambience,a,b,.055,muted)
     for j in range(3):
      var leaf = sphere(ambience,pos+Vector3(side*.12,.11,-.3+j*.3),.17,muted); leaf.scale = Vector3(.7,.27,1.5); leaf.rotation.y = side*.5
    1:
     var shard = box(ambience,pos+Vector3(0,.2,0),Vector3(.16,.75,.17),bright); shard.rotation = Vector3(.12,0,side*.25)
     box(ambience,pos+Vector3(-side*.16,.1,.1),Vector3(.12,.44,.12),muted)
    2:
     for j in range(3): box(ambience,pos+Vector3(side*.07,.1,j*.13),Vector3(.12,.025,.07),bright)
     var glow = OmniLight3D.new(); ambience.add_child(glow); glow.position = pos+Vector3(0,.3,0); glow.light_color = color; glow.light_energy = .22; glow.omni_range = 1.1
    3:
     box(ambience,pos,Vector3(.22,.06,1.2),material(Color("756348")))
     sphere(ambience,pos+Vector3(0,.08,.3),.10,bright)
    4:
     box(ambience,pos+Vector3(0,.12,0),Vector3(.16,.35,.74),muted)
     for j in range(4): box(ambience,pos+Vector3(-side*.09,.16,-.26+j*.17),Vector3(.03,.1,.09),bright)
 # Accent lighting and geometry change the ship's local atmosphere, not only its planet icon.
 var light = OmniLight3D.new(); ambience.add_child(light); light.position = Vector3(0,4,-4); light.light_color = color; light.light_energy = .45; light.omni_range = 11
func make_showcase() -> void:
 for child in showcase.get_children(): child.queue_free()
 stage_models.clear()
 if game.screen in ["intro","travel","ending","menu","new"]:
  var ship = model("res://assets3d/ship.glb"); showcase.add_child(ship); ship.scale = Vector3.ONE*(.50 if game.screen == "intro" else .35)
  ship.position = position_for(Vector2(460,795 if game.screen == "intro" else (783 if game.screen == "travel" else 491)),1.0); ship.rotation.y = -.4; stage_models.ship = ship; stage_models.home = ship.position
  var hull = int(game.run.data.get("hull",0))
  if hull > 0: paint_ship(ship,AstraCards.COLORS[(hull-1)%5].darkened(.35))
  if game.screen == "intro":
   var carrier = model("res://assets3d/carrier.glb"); showcase.add_child(carrier); carrier.scale = Vector3.ONE*.31; carrier.position = position_for(Vector2(243,738),1); carrier.rotation.y = .7; stage_models.carrier = carrier; stage_models.carrier_home = carrier.position
   var core = sphere(showcase,position_for(Vector2(310,748),1.1),.18,material(Color("52d8c0"),2.3)); stage_models.core = core; stage_models.core_home = core.position
func animate_showcase(delta: float) -> void:
 if not stage_models.has("ship"): return
 var ship: Node3D = stage_models.ship
 ship.position = stage_models.home+Vector3(0,sin(stage_clock*1.8)*.11,0)
 ship.rotation.z = sin(stage_clock*.75)*.025
 if stage_models.has("carrier"):
  var carrier: Node3D = stage_models.carrier
  var core: Node3D = stage_models.core
  var progress = clampf(stage_clock/5.5,0,1)
  carrier.position = stage_models.carrier_home+Vector3(-progress*.5,.15*sin(stage_clock),-progress*.35)
  core.position = stage_models.core_home.lerp(carrier.position+Vector3(0,.5,0),smoothstep(0,1,progress)); core.rotation.y += delta
func paint_ship(node: Node, color: Color) -> void:
 if node is MeshInstance3D and node.mesh != null:
  for surface in range(node.mesh.get_surface_count()):
   var mat: Material = node.mesh.surface_get_material(surface)
   if mat is StandardMaterial3D and (mat.resource_name.to_lower().contains("armor") or mat.resource_name.to_lower().contains("hull")):
    var custom = mat.duplicate(); custom.albedo_color = color; node.set_surface_override_material(surface,custom)
 for child in node.get_children(): paint_ship(child,color)
