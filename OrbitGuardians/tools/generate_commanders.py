"""Original five opposing commanders and role-coloured robot portraits in Blender.
Preserves existing editable libraries; creates AstraCommanders.blend.
"""
from pathlib import Path
from math import sin,cos,pi
import bpy
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets3d/commanders';POR=OUT/'portraits';ROLE=ROOT/'assets3d/roles/portraits'
for p in (OUT,POR,ROLE):p.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.context.preferences.filepaths.save_version=0
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=False
scene.render.threads_mode='FIXED';scene.render.threads=4;scene.render.resolution_x=scene.render.resolution_y=384
scene.render.resolution_percentage=100;scene.render.film_transparent=True;scene.world.color=(.12,.15,.19);scene.view_settings.view_transform='AgX'
objects=[];collection=None;libraries=[]
def mat(name,rgb,metal=.5,emit=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*rgb,1);m.use_nodes=True;b=m.node_tree.nodes.get('Principled BSDF')
 b.inputs['Base Color'].default_value=(*rgb,1);b.inputs['Metallic'].default_value=metal;b.inputs['Roughness'].default_value=.35
 if emit:b.inputs['Emission Color'].default_value=(*rgb,1);b.inputs['Emission Strength'].default_value=emit
 return m
def finish(o,m):
 for c in list(o.users_collection):c.objects.unlink(o)
 collection.objects.link(o);objects.append(o);o.data.materials.append(m);return o
def box(name,p,s,m):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.name=name;o.scale=s;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 mod=o.modifiers.new('Machined edges','BEVEL');mod.width=.045;mod.segments=2;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 return finish(o,m)
def orb(name,p,r,m):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,radius=r,location=p);o=bpy.context.object;o.name=name
 for face in o.data.polygons:face.use_smooth=True
 return finish(o,m)
def cone(name,p,r,d,m):
 bpy.ops.mesh.primitive_cone_add(vertices=8,radius1=r,radius2=0,depth=d,location=p);o=bpy.context.object;o.name=name;return finish(o,m)
steel=mat('Dark articulated metal',(.025,.04,.065));face=mat('Obsidian face screen',(.012,.025,.04),.25)
colors=[(.20,.68,.40),(.20,.65,.94),(.98,.20,.055),(.83,.58,.15),(.55,.18,.87)]
for act,color in enumerate(colors):
 collection=bpy.data.collections.new(['Marshal Thorn','Lady Vega','Helion','Seraph','The Zero Mind'][act]);scene.collection.children.link(collection);objects=[]
 body=mat(collection.name+' enamel',color);edge=mat(collection.name+' pale armour',tuple(.5+.35*c for c in color));glow=mat(collection.name+' status lights',color,.2,2)
 for side in (-1,1):
  box('Boot',(side*.38,0,.28),(.6,.85,.32),steel);box('Shin',(side*.37,0,.77),(.44,.46,.74),body)
  orb('Knee',(side*.37,0,1.19),.22,edge);box('Upper leg',(side*.35,0,1.52),(.42,.48,.58),steel)
  box('Shoulder',(side*.97,0,2.55),(.64,.7,.6),body);orb('Shoulder joint',(side*.73,0,2.46),.24,steel)
  box('Forearm',(side*1.06,-.04,1.85),(.37,.43,.79),edge);box('Gauntlet',(side*1.08,-.05,1.37),(.44,.52,.4),body)
 box('Torso',(0,0,2.13),(1.33,.77,1.28),body);box('Breastplate',(0,-.43,2.2),(1.02,.13,.82),edge)
 orb('Reactor emblem',(0,-.55,2.26),.20,glow);box('Neck',(0,0,2.9),(.3,.3,.25),steel)
 box('Helmet',(0,0,3.28),(.88,.71,.74),body);box('Face screen',(0,-.40,3.27),(.68,.08,.38),face)
 for side in (-1,1):box('Eye slit',(side*.18,-.46,3.31),(.22,.035,.045),glow)
 if act==0:
  for side in (-1,1):
   for i in range(3):cone('Antler armour',(side*(.50+i*.12),0,3.67+i*.14),.11,.62,body)
  for side in (-1,1):box('Moss mantle',(side*.75,.43,2.45),(.45,.15,.95),body)
 elif act==1:
  for side in (-1,1):
   for i in range(3):cone('Crystal pauldron',(side*(.86+i*.16),0,2.98),.13,.7+.15*i,glow)
  for i in range(5):cone('Ice crown',((i-2)*.19,0,3.80),.10,.55+(.35 if i==2 else 0),edge)
 elif act==2:
  orb('Furnace heart',(0,-.59,2.24),.32,glow)
  for side in (-1,1):
   box('Exhaust stack',(side*.56,.43,2.85),(.28,.38,1.23),steel)
   for i in range(3):box('Hot furnace vent',(side*.40,-.54,2.04+i*.18),(.16,.035,.07),glow)
 elif act==3:
  box('Royal backplate',(0,.51,2.5),(1.8,.14,1.95),body)
  for side in (-1,1):cone('Helm crest',(side*.5,0,3.65),.18,.65,edge)
  box('Ancient vault jaw',(0,-.45,3.02),(.75,.12,.21),edge)
 else:
  for i in range(8):orb('Quantum halo',(sin(i*pi/4)*.85,.2,3.28+cos(i*pi/4)*.85),.07,glow)
  for side in (-1,1):
   for i in range(3):box('Floating circuit',(side*(.85+i*.2),.03,2.7+i*.18),(.16,.22,.16),glow)
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0]
 # One exported draw object, separate editable parts retained in the library.
 copies=[]
 for o in objects:
  dup=o.copy();dup.data=o.data.copy();scene.collection.objects.link(dup);copies.append(dup);o.select_set(False);dup.select_set(True)
 bpy.context.view_layer.objects.active=copies[0];bpy.ops.object.join()
 merged=bpy.context.object;merged.name=collection.name+' export'
 bpy.ops.export_scene.gltf(filepath=str(OUT/f'world_{act}.glb'),export_format='GLB',use_selection=True,export_yup=True)
 bpy.data.objects.remove(merged,do_unlink=True);libraries.append((collection,objects.copy(),POR/f'world_{act}.png'))
# Role portraits come from original exported geometry, not painted 2D screenshots.
roles={'pulse':(.99,.38,.22),'reactor':(.20,.94,.75),'shield':(1,.74,.13),'cryo':(.24,.72,1),'burst':(.99,.38,.22),'rail':(.68,.31,.95),'mortar':(.99,.38,.22),'repair':(.3,.94,.53),'nova':(.68,.31,.95)}
for art,color in roles.items():
 if art=='pulse':
  with bpy.data.libraries.load(str(ROOT.parent/'OrbitGuardians-Blender/AstraDioramas.blend'),link=False) as (source,target):
   target.collections=['Player / original exploration robot']
  coll=target.collections[0];scene.collection.children.link(coll);items=list(coll.all_objects)
 else:
  before=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=str(ROOT/f'assets3d/tabletop/card_{art}.glb'))
  items=list(set(bpy.data.objects)-before);coll=bpy.data.collections.new('Role / '+art);scene.collection.children.link(coll)
 for o in items:
  for c in list(o.users_collection):c.objects.unlink(o)
  coll.objects.link(o)
  if o.type!='MESH':continue
  for i,m in enumerate(o.data.materials):
   if not m or not m.use_nodes:continue
   clone=m.copy();b=clone.node_tree.nodes.get('Principled BSDF')
   if b:
    old=b.inputs['Base Color'].default_value
    if sum(old[:3])/3>.16 and b.inputs['Emission Strength'].default_value<.01:
     b.inputs['Base Color'].default_value=tuple((((color[j]+.055)/1.055)**2.4)*.72 for j in range(3))+(1,)
   o.data.materials[i]=clone
 libraries.append((coll,items,ROLE/f'{art}.png'))
bpy.ops.object.camera_add();camera=bpy.context.object;camera.data.type='ORTHO';scene.camera=camera
lights=[]
for pos,power in [((-3,-4,6),550),((4,-1,5),700),((0,4,5),750)]:
 bpy.ops.object.light_add(type='AREA',location=pos);lamp=bpy.context.object;lamp.data.energy=power;lamp.data.shape='DISK';lamp.data.size=4;lights.append(lamp)
for coll,items,path in libraries:
 for c,_,_ in libraries:c.hide_render=c!=coll
 bpy.context.view_layer.update()
 points=[o.matrix_world@Vector(v) for o in items if o.type=='MESH' for v in o.bound_box]
 center=Vector([(min(p[i] for p in points)+max(p[i] for p in points))/2 for i in range(3)])
 height=max(p.z for p in points)-min(p.z for p in points)
 camera.location=center+Vector((height*.68,-height*1.6,height*.65));camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.ortho_scale=max(max(p[i] for p in points)-min(p[i] for p in points) for i in range(3))*1.55
 for i,lamp in enumerate(lights):
  lamp.location=center+Vector([(-3,-4,6),(4,-1,5),(0,4,5)][i]);lamp.rotation_euler=(center-lamp.location).to_track_quat('-Z','Y').to_euler()
 scene.render.filepath=str(path);bpy.ops.render.render(write_still=True);print('PORTRAIT:',path.name,flush=True)
for index,(coll,items,_) in enumerate(libraries):
 coll.hide_render=False
 for o in items:
  if o.parent is None:o.location.x+=(index%5)*5;o.location.y+=(index//5)*6
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT.parent/'OrbitGuardians-Blender/AstraCommanders.blend'))
print('COMMANDERS COMPLETE: five originals, nine role portraits, editable Blender library')
