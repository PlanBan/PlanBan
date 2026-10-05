"""Original articulated Forge robots. Blender 4.3+, no downloaded assets.
Generates sixteen distinct GLBs with Idle/Deploy/Attack/Hit/Death, portraits,
and the editable AstraForge.blend. Existing libraries are never rewritten.
"""
from pathlib import Path
import bpy,math,json
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets3d/forge';POR=OUT/'portraits'
POR.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=64;scene.cycles.use_denoising=False
scene.render.threads_mode='FIXED';scene.render.threads=4;scene.render.fps=30
scene.render.resolution_x=scene.render.resolution_y=384;scene.render.resolution_percentage=100
scene.render.film_transparent=True;scene.view_settings.view_transform='AgX';scene.world.color=(.045,.055,.075)
bpy.context.preferences.filepaths.save_version=0
library=[];parts=[];rig=None;coll=None

def mat(name,color,emission=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;n=m.node_tree.nodes.get('Principled BSDF')
 n.inputs['Base Color'].default_value=(*color,1);n.inputs['Metallic'].default_value=.72;n.inputs['Roughness'].default_value=.3
 if emission:n.inputs['Emission Color'].default_value=(*color,1);n.inputs['Emission Strength'].default_value=emission
 return m
DARK=mat('Graphite alloy',(.035,.05,.072));STEEL=mat('Machined titanium',(.30,.38,.47));WHITE=mat('Ceramic trim',(.72,.78,.83));BLACK=mat('Obsidian glass',(.004,.012,.021))

def piece(o,m,bone='Body',bevel=0):
 for c in list(o.users_collection):c.objects.unlink(o)
 coll.objects.link(o);o.data.materials.append(m)
 if bevel:
  b=o.modifiers.new('Machined bevel','BEVEL');b.width=bevel;b.segments=2;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=b.name)
  n=o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');bpy.ops.object.modifier_apply(modifier=n.name)
 o.parent=rig;group=o.vertex_groups.new(name=bone);group.add(list(range(len(o.data.vertices))),1,'REPLACE')
 mod=o.modifiers.new('Rigid articulated skin','ARMATURE');mod.object=rig;parts.append(o);return o

def box(name,p,d,m,bone='Body',angle=0):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.name=name;o.scale=d;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.rotation_euler.z=angle
 return piece(o,m,bone,min(d)*.13)

def orb(name,p,r,m,bone='Head',scale=(1,1,1)):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,radius=r,location=p);o=bpy.context.object;o.name=name;o.scale=scale
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 for f in o.data.polygons:f.use_smooth=True
 return piece(o,m,bone)

def cyl(name,p,r,h,m,bone='Body',axis=(0,0,1),vertices=20):
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=h,location=p);o=bpy.context.object;o.name=name;o.rotation_euler=Vector(axis).to_track_quat('Z','Y').to_euler()
 return piece(o,m,bone,min(r*.13,.025))

def link(name,a,b,width,m,bone='Body'):
 a=Vector(a);b=Vector(b);o=box(name,(a+b)/2,(width,width,(a-b).length),m,bone);o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o

def ring(name,p,major,minor,m,bone='Body',axis=(0,0,1)):
 bpy.ops.mesh.primitive_torus_add(major_segments=24,minor_segments=8,location=p,major_radius=major,minor_radius=minor);o=bpy.context.object;o.name=name;o.rotation_euler=Vector(axis).to_track_quat('Z','Y').to_euler()
 for f in o.data.polygons:f.use_smooth=True
 return piece(o,m,bone)

def skeleton(name):
 global rig,coll,parts
 parts=[];coll=bpy.data.collections.new('Forge / '+name);scene.collection.children.link(coll)
 bpy.ops.object.armature_add();rig=bpy.context.object;rig.name=name+' / articulated rig'
 for c in list(rig.users_collection):c.objects.unlink(rig)
 coll.objects.link(rig);bpy.ops.object.mode_set(mode='EDIT');bones=rig.data.edit_bones;bones.remove(bones[0])
 for name,p,parent in [('Root',(0,0,0),None),('Body',(0,0,.8),'Root'),('Head',(0,0,1.35),'Body'),('Weapon',(0,-.3,1),'Body'),('Leg.L',(-.42,0,.45),'Root'),('Leg.R',(.42,0,.45),'Root')]:
  b=bones.new(name);b.head=p;b.tail=Vector(p)+Vector((0,0,.3))
  if parent:b.parent=bones[parent]
 bpy.ops.object.mode_set(mode='OBJECT')
 for b in rig.pose.bones:b.rotation_mode='XYZ'

def legs(count,height=.66):
 for i in range(count):
  angle=math.tau*i/count+math.pi/4;x=math.cos(angle);y=math.sin(angle);bone='Leg.L' if x<0 else 'Leg.R'
  a=(x*.38,y*.25,height);b=(x*.62,y*.44,.32);c=(x*.81,y*.65,.1)
  orb('Hip joint',a,.095,STEEL,bone);link('Articulated upper leg',a,b,.12,DARK,bone);link('Leg armour',b,c,.15,STEEL,bone)
  box('Magnetic foot',c,(.27,.35,.13),DARK,bone)

def biped(accent,tall=False):
 for sign,bone in [(-1,'Leg.L'),(1,'Leg.R')]:
  hip=(sign*.26,.09,.80);knee=(sign*.32,-.10,.40);ankle=(sign*.27,.10,.15)
  orb('Hip bearing',hip,.12,STEEL,bone);link('Armoured thigh',hip,knee,.20,accent,bone);orb('Knee bearing',knee,.10,DARK,bone);link('Reverse shin',knee,ankle,.16,WHITE,bone)
  box('Split boot',(sign*.27,-.13,.08),(.28,.45,.17),DARK,bone)
 box('Sloping breastplate',(0,0,1.02),(.83,.48,.55),accent);box('Upper engine spine',(0,.27,1.02),(.42,.24,.53),DARK)
 for sign in [-1,1]:
  orb('Shoulder coupling',(sign*.45,0,1.16),.14,STEEL);box('Layered shoulder pad',(sign*.52,.03,1.21),(.32,.45,.26),WHITE)
 box('Angled helmet',(0,-.035,1.52),(.60,.43,.36),DARK,'Head')
 box('Visor',(0,-.265,1.54),(.48,.055,.16),BLACK,'Head')
 for sign in [-1,1]:box('Optical strip',(sign*.14,-.30,1.55),(.13,.018,.055),GLOW,'Head')
 ring('Chest power bezel',(0,-.26,1.03),.15,.035,STEEL,axis=(0,-1,0));cyl('Chest power lens',(0,-.284,1.03),.12,.04,GLOW,axis=(0,-1,0))

def barrel(x,y,z,length=.6,r=.085):
 cyl('Segmented barrel',(x,y,z),r,length,DARK,'Weapon',(0,-1,0))
 for offset in [-.24,0,.24]:ring('Barrel cooling ring',(x,y+offset,z),r+.015,.022,STEEL,'Weapon',(0,-1,0))
 cyl('Muzzle lens',(x,y-length/2-.015,z),r*.65,.025,GLOW,'Weapon',(0,-1,0))

names=['pulse','reactor','shield','cryo','burst','rail','mortar','repair','nova','enemy_drone','enemy_runner','enemy_tank','enemy_medic','enemy_disruptor','enemy_elite','enemy_boss']
colors={'pulse':(.08,.40,.65),'reactor':(.05,.57,.39),'shield':(.75,.43,.035),'cryo':(.1,.65,.79),'burst':(.82,.23,.06),'rail':(.28,.18,.62),'mortar':(.61,.29,.06),'repair':(.25,.56,.35),'nova':(.50,.13,.70)}
for name in names:
 skeleton(name);enemy=name.startswith('enemy_');accent=mat(('EnemyFaction' if enemy else 'RoleAccent')+' / '+name,colors.get(name,(.26,.31,.35)))
 GLOW=mat('Optics / '+name,(.95,.075,.025) if enemy else (.10,.83,1) if name not in ['shield','repair','nova'] else {'shield':(1,.64,.06),'repair':(.18,1,.42),'nova':(.67,.2,1)}[name],2.5)
 if name in ['pulse','rail','enemy_runner','enemy_elite']:
  biped(accent)
  if name=='pulse':barrel(.51,-.29,1.00,.63);box('Forearm gauntlet',(-.51,-.16,.96),(.20,.27,.33),STEEL)
  elif name=='rail':
   barrel(.56,-.58,1.06,1.15,.085);link('Rail accelerator',(.53,-.99,1.13),(.53,-.08,1.13),.065,GLOW,'Weapon');box('Sniper stabiliser',(0,.40,1.21),(.60,.19,.37),accent)
  else:
   for sign in [-1,1]:
    link('Blade arm',(sign*.53,-.15,1.0),(sign*.78,-.61,.58),.11,STEEL,'Weapon');link('Luminous blade',(sign*.78,-.61,.58),(sign*.95,-.83,.23),.09,GLOW,'Weapon')
   if name=='enemy_elite':
    for sign in [-1,1]:link('Hunter crest',(sign*.20,0,1.67),(sign*.38,.08,1.93),.09,STEEL,'Head')
 elif name in ['reactor','shield','burst','mortar','enemy_drone','enemy_tank','enemy_boss']:
  legs(6 if name in ['enemy_tank','enemy_boss'] else 4)
  box('Armoured carapace',(0,0,.75),(1.09,.87,.42),accent)
  box('Underframe',(0,.06,.51),(.85,.61,.20),DARK)
  if name=='reactor':
   orb('Energy containment',(0,0,1.00),.35,WHITE,'Head',(.88,.88,.76));ring('Magnetic ring',(0,0,1.04),.37,.044,GLOW,'Head');cyl('Generator cap',(0,0,1.27),.23,.10,STEEL,'Head')
   for sign in [-1,1]:cyl('Cooling stack',(sign*.46,.16,.98),.12,.42,DARK)
  elif name in ['shield','enemy_tank']:
   cyl('Faceted shield',(0,-.52,.99),.62,.12,accent,'Weapon',(0,-1,0),6)
   for x in [-.28,0,.28]:box('Shield conductor',(x,-.60,1.00),(.035,.035,.59),GLOW,'Weapon')
   for x in [-.57,.57]:barrel(x,-.32,.94,.38,.085)
  elif name=='burst':
   for x in [-.37,.37]:box('Twin turret',(x,-.12,1.08),(.28,.45,.27),DARK,'Weapon');barrel(x,-.50,1.08,.56,.095)
  elif name=='mortar':
   for x in [-.42,.42]:
    box('Rocket pod',(x,.12,1.18),(.34,.63,.43),DARK,'Weapon')
    for z in [.08,.25]:cyl('Rocket socket',(x,-.215,1.03+z),.10,.06,STEEL,'Weapon',(0,-1,0));cyl('Rocket tip',(x,-.257,1.03+z),.064,.05,GLOW,'Weapon',(0,-1,0))
  elif name=='enemy_boss':
   box('Fortress chest',(0,0,1.16),(.80,.73,.56),DARK);orb('Furnace heart',(0,-.39,1.12),.23,GLOW,'Head');ring('Heart guard',(0,-.46,1.12),.29,.06,STEEL,'Head',(0,-1,0))
   for x in [-.54,.54]:barrel(x,-.52,1.42,.68,.13);box('Tall bastion',(x,.12,1.55),(.31,.35,.80),accent)
   box('Crown',(0,0,1.67),(.57,.32,.23),STEEL,'Head')
  else:
   orb('Scanner shell',(0,-.15,.99),.30,DARK,'Head',(.95,1,.66));barrel(0,-.52,.90,.33,.1)
   for x in [-.45,.45]:cyl('Scanner eye',(x,-.42,.90),.11,.07,GLOW,'Head',(0,-1,0))
 else:
  orb('Hover chassis',(0,0,.76),.38,WHITE if not enemy else DARK,'Body',(1,1,.72));ring('Levitation engine',(0,0,.50),.32,.045,GLOW)
  for x in [-.65,.65]:
   link('Floating wing root',(0,0,.80),(x,.12,.83),.11,STEEL);box('Wing armour',(x,.06,.87),(.29,.49,.10),accent,'Weapon',angle=x*.35)
   orb('Wing thruster',(x,.05,.72),.11,GLOW,'Weapon')
  if name in ['repair','enemy_medic']:
   cyl('Medical disc',(0,-.36,.82),.24,.075,DARK,'Head',(0,-1,0));box('Medic cross H',(0,-.411,.82),(.28,.035,.085),GLOW,'Head');box('Medic cross V',(0,-.411,.82),(.085,.035,.28),GLOW,'Head')
  elif name=='cryo':
   for x in [-.20,.20]:barrel(x,-.36,.87,.55,.06)
   ring('Cold condenser',(0,0,1.09),.22,.055,GLOW,'Head')
  else:
   orb('Quantum heart',(0,0,1.0),.22,GLOW,'Head')
   for i in range(3):
    a=i*math.tau/3;x=math.cos(a)*.4;y=math.sin(a)*.4
    link('Containment claw',(x,y,.76),(x*.7,y*.7,1.43),.08,accent,'Head')
 # Export copies merged for efficiency, retain original named parts in the editable collection.
 originals=list(parts);copies=[]
 bpy.ops.object.select_all(action='DESELECT')
 for o in originals:
  d=o.copy();d.data=o.data.copy();coll.objects.link(d);d.select_set(True);copies.append(d)
 bpy.context.view_layer.objects.active=copies[0];bpy.ops.object.join();merged=bpy.context.object;merged.name=name+' / export mesh'
 rig.animation_data_create()
 for clip,length in [('Idle',60),('Deploy',24),('Attack',20),('Hit',14),('Death',25)]:
  action=bpy.data.actions.new(name+'_'+clip);rig.animation_data.action=action
  for f in [1,int(length*.25),int(length*.5),int(length*.75),length]:
   t=(f-1)/(length-1)
   for b in rig.pose.bones:b.location=(0,0,0);b.rotation_euler=(0,0,0);b.scale=(1,1,1)
   b=rig.pose.bones;k=math.sin(t*math.pi)
   if clip=='Idle':b['Body'].location.y=.04*math.sin(t*math.tau);b['Head'].rotation_euler.y=.06*math.sin(t*math.tau);b['Weapon'].rotation_euler.y=.035*math.sin(t*math.tau)
   elif clip=='Deploy':
    u=min(1,t*2);b['Root'].scale=(.15+.85*u,)*3;b['Body'].location.y=.35*(1-u)+.09*k;b['Leg.L'].rotation_euler.z=(1-u)*.6;b['Leg.R'].rotation_euler.z=-(1-u)*.6
   elif clip=='Attack':b['Weapon'].location.z=.19*k;b['Body'].rotation_euler.x=.13*k;b['Leg.L'].rotation_euler.x=-.12*k;b['Head'].rotation_euler.x=-.08*k
   elif clip=='Hit':b['Body'].location.z=.12*k;b['Head'].rotation_euler.x=-.19*k
   else:b['Root'].rotation_euler.x=min(1,t*1.3)*1.3;b['Root'].location.y=-.24*t;b['Head'].rotation_euler.y=.35*t;b['Weapon'].rotation_euler.x=.5*t
   for bone in b:bone.keyframe_insert('location',frame=f);bone.keyframe_insert('rotation_euler',frame=f);bone.keyframe_insert('scale',frame=f)
  rig.animation_data.action=None;track=rig.animation_data.nla_tracks.new();track.name=clip;strip=track.strips.new(clip,1,action);strip.extrapolation='NOTHING'
 for b in rig.pose.bones:b.location=(0,0,0);b.rotation_euler=(0,0,0);b.scale=(1,1,1)
 scene.frame_set(0);bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);merged.select_set(True);bpy.context.view_layer.objects.active=rig
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_animation_mode='NLA_TRACKS',export_frame_range=False,export_anim_single_armature=False,export_skins=True,export_yup=True,export_cameras=False,export_lights=False)
 bpy.data.objects.remove(merged,do_unlink=True);library.append((name,coll,rig,originals))
bpy.ops.object.camera_add();camera=bpy.context.object;camera.data.type='ORTHO';scene.camera=camera
lights=[]
for p,power,size in [((-3,-4,6),650,4),((4,-1,4),850,4),((0,4,5),1000,3)]:
 bpy.ops.object.light_add(type='AREA',location=p);l=bpy.context.object;l.data.energy=power;l.data.size=size;lights.append(l)
for name,coll,rig,items in library:
 for _,c,_,_ in library:c.hide_render=c!=coll
 bpy.context.view_layer.update();points=[o.matrix_world@Vector(p) for o in items for p in o.bound_box]
 center=Vector([(min(p[i] for p in points)+max(p[i] for p in points))/2 for i in range(3)]);extent=max(max(p[i] for p in points)-min(p[i] for p in points) for i in range(3))
 camera.location=center+Vector((extent*.75,-extent*1.7,extent*.85));camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.ortho_scale=extent*1.4
 for l,p in zip(lights,[(-3,-4,6),(4,-1,4),(0,4,5)]):l.location=center+Vector(p);l.rotation_euler=(center-l.location).to_track_quat('-Z','Y').to_euler()
 scene.render.filepath=str(POR/(name+'.png'));bpy.ops.render.render(write_still=True);print('FORGE MODEL:',name,flush=True)
for index,(_,c,rig,_) in enumerate(library):c.hide_render=False;rig.location.x+=(index%4)*4;rig.location.y+=(index//4)*4
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT.parent/'OrbitGuardians-Blender/AstraForge.blend'))
(OUT/'manifest.json').write_text(json.dumps({'models':names,'clips':['Idle','Deploy','Attack','Hit','Death'],'original':True},indent=2))
print('FORGE COMPLETE: sixteen original articulated models and portraits',flush=True)
