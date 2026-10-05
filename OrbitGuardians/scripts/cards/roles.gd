extends RefCounted
class_name AstraRoles
const HP = Color("51baff")
const ATTACK = Color("ff526b")
const DEFENCE = Color("ffd34e")
static func color(entry: Dictionary) -> Color:
 if entry.get("armor",0)+entry.get("shield",0)+entry.get("temporary",0)>0 or entry.get("effect","") in ["guard","armor","barrier"]: return DEFENCE
 match entry.get("effect",""):
  "heal","mend","coreheal","regen": return Color("6feba0")
  "freeze","frost","emp","chill","softfrost": return Color("5ccbff")
  "energy","boost","storm": return Color("65f2cf")
  "refund","double","burn","splash": return Color("ff7754")
  "pierce","deathburst","overload","echo": return Color("c08aff")
 return ATTACK
static func paint(root: Node, entry: Dictionary) -> void:
 var tint = color(entry)
 for mesh in root.find_children("*","MeshInstance3D",true,false):
  if mesh.mesh == null: continue
  for surface in range(mesh.mesh.get_surface_count()):
   var source = mesh.mesh.surface_get_material(surface)
   if not source is StandardMaterial3D: continue
   var material: StandardMaterial3D = source.duplicate()
   var lightness = material.albedo_color.get_luminance()
   # Keep face screens, dark joints, glass and bright status lamps legible.
   if lightness > .16 and not material.emission_enabled:
    material.albedo_color = tint.darkened(.22)
    material.metallic = .48; material.roughness = .33
   elif material.emission_enabled:
    material.emission = tint; material.emission_energy_multiplier = .8
   mesh.set_surface_override_material(surface,material)
