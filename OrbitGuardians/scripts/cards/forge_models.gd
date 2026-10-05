extends RefCounted
class_name AstraForgeModels
static func key(entry: Dictionary) -> String:
 return "enemy_"+str(entry.id) if str(entry.get("art","")).begins_with("p") and entry.id in AstraCards.ENEMIES else str(entry.art)
static func model_path(entry: Dictionary) -> String:
 return "res://assets3d/forge/%s.glb" % key(entry)
static func portrait(entry: Dictionary) -> String:
 return "res://assets3d/forge/portraits/%s.png" % key(entry)
static func paint(root: Node, entry: Dictionary, act: int) -> void:
 for mesh in root.find_children("*","MeshInstance3D",true,false):
  for i in range(mesh.mesh.get_surface_count()):
   var original:Material=mesh.get_active_material(i)
   if not original is StandardMaterial3D:continue
   if original.resource_name.contains("EnemyFaction"):
    var mat=original.duplicate();mat.albedo_color=AstraCards.COLORS[act].darkened(.30);mesh.set_surface_override_material(i,mat)
   elif original.resource_name.contains("Machined titanium") and entry.get("armor",0)>0:
    var mat=original.duplicate();mat.albedo_color=AstraRoles.DEFENCE;mesh.set_surface_override_material(i,mat)
