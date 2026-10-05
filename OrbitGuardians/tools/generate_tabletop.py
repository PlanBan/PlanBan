"""Original industrial table and distinct card mechs. Blender 4.3+, CPU Cycles.
Run: blender --background --factory-startup --python tools/generate_tabletop.py
No external models, card frames, or game artwork are used.
"""
from pathlib import Path
import bpy, math, random, json, sys
SKIP_PORTRAITS="--skip-portraits" in sys.argv
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets3d'/'tabletop'; PORTRAITS=OUT/'portraits'
SOURCE=ROOT.parent/'OrbitGuardians-Blender'
for p in (OUT,PORTRAITS,SOURCE):p.mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=48;scene.cycles.use_denoising=False
scene.render.threads_mode='FIXED';scene.render.threads=4
scene.render.resolution_x=scene.render.resolution_y=384;scene.render.resolution_percentage=100
scene.render.film_transparent=True;scene.view_settings.view_transform='AgX'
scene.world.color=(.06,.07,.08);random.seed(77183)
collection=None;objects=[];manifest={}
def mat(name,color,metal=.7,rough=.4,emit=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 n=m.node_tree.nodes.get('Principled BSDF');n.inputs['Base Color'].default_value=(*color,1);n.inputs['Metallic'].default_value=metal;n.inputs['Roughness'].default_value=rough
 if emit:n.inputs['Emission Color'].default_value=(*color,1);n.inputs['Emission Strength'].default_value=emit
 return m
STEEL=mat('Worn graphite steel',(.095,.11,.105));EDGE=mat('Brushed pale titanium',(.34,.39,.37),.85,.28)
PANEL=mat('Oxidised table surface',(.16,.19,.17),.72,.55);DARK=mat('Deep recess',(.014,.023,.021),.4,.6)
WHITE=mat('Moon ceramic',(.7,.72,.63),.4,.29);CYAN=mat('Astra cyan',(.04,.72,.64),.2,.3,2)
AMBER=mat('Old tungsten',(.95,.48,.08),.2,.3,2);RED=mat('Hostile light',(.95,.09,.025),.2,.3,3)
RUST=mat('Old copper',(.27,.15,.075),.75,.6);SCRATCH=mat('Exposed scratch',(.26,.28,.22),.8,.55)
def start(name):
 global collection,objects
 collection=bpy.data.collections.new(name);scene.collection.children.link(collection);objects=[]
def finish(o,m):
 for c in list(o.users_collection):c.objects.unlink(o)
 collection.objects.link(o);o.data.materials.append(m);objects.append(o);return o
def box(name,p,s,m,bevel=.04):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.name=name;o.scale=s;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  mod=o.modifiers.new('Machined edges','BEVEL');mod.width=min(bevel,min(s)*.22);mod.segments=2;bpy.ops.object.modifier_apply(modifier=mod.name)
  mod=o.modifiers.new('Normals','WEIGHTED_NORMAL');bpy.ops.object.modifier_apply(modifier=mod.name)
 return finish(o,m)
def cyl(name,p,r,d,m,rotation=(0,0,0),verts=24):
 bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=d,location=p,rotation=rotation);o=bpy.context.object;o.name=name
 mod=o.modifiers.new('Edge bevel','BEVEL');mod.width=.02;mod.segments=2;bpy.ops.object.modifier_apply(modifier=mod.name)
 for poly in o.data.polygons:poly.use_smooth=True
 return finish(o,m)
def orb(name,p,r,m,scale=(1,1,1)):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,radius=r,location=p);o=bpy.context.object;o.name=name;o.scale=scale
 for poly in o.data.polygons:poly.use_smooth=True
 return finish(o,m)
def beam(name,a,b,r,m):
 a,b=Vector(a),Vector(b);o=cyl(name,(a+b)/2,r,(b-a).length,m);o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o
def ring(name,p,r,thickness,m,rotation=(0,0,0)):
 bpy.ops.mesh.primitive_torus_add(major_radius=r,minor_radius=thickness,major_segments=32,minor_segments=8,location=p,rotation=rotation)
 o=bpy.context.object;o.name=name;return finish(o,m)
def cable(name,pts,m,r=.05):
 c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.bevel_depth=r;c.bevel_resolution=2
 s=c.splines.new('BEZIER');s.bezier_points.add(len(pts)-1)
 for p,co in zip(s.bezier_points,pts):p.co=co;p.handle_left_type=p.handle_right_type='AUTO'
 o=bpy.data.objects.new(name,c);collection.objects.link(o);bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.convert(target='MESH');o.select_set(False);o.data.materials.append(m);objects.append(o)
def export(name):
 bpy.ops.object.select_all(action='DESELECT')
 copies=[]
 for source in objects:
  duplicate=source.copy();duplicate.data=source.data.copy();scene.collection.objects.link(duplicate);duplicate.select_set(True);copies.append(duplicate)
 bpy.context.view_layer.objects.active=copies[0];bpy.ops.object.join();merged=bpy.context.object;merged.name=name
 # A merged export cuts hundreds of static draw calls; editable originals stay separated.
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_yup=True)
 bpy.data.objects.remove(merged,do_unlink=True)
 manifest[name]={'objects':len(objects),'vertices':sum(len(o.data.vertices) for o in objects if o.type=='MESH')}
start('Spark / tactical table')
box('Forged chassis',(0,0,-.32),(10.6,16,.65),STEEL,.14)
box('Recessed working surface',(0,0,.025),(9.45,14.5,.1),PANEL)
for x in (-5.03,5.03):
 box('Raised rail',(x,0,.17),(.25,15.6,.3),EDGE)
 for y in range(-7,8):
  cyl('Hex bolt',(x,y,.34),.085,.03,DARK,verts=6)
  if y%3==0:box('Guide light',(x,y,.35),(.09,.48,.015),CYAN)
for y in (-7.7,7.7):box('End rail',(0,y,.16),(10.3,.24,.25),EDGE)
for x in (-3.54,-1.17,1.17,3.54):
 for y in (-1.4,1.4):
  box('Card tray',(x,y,.13),(2.1,2.7,.055),DARK,.04)
  for dx in (-.99,.99):box('Tray rail',(x+dx,y,.17),(.025,2.45,.025),SCRATCH,.005)
for i in range(110):
 x=random.uniform(-4.6,4.6);y=random.uniform(-7.1,7.1)
 o=box('Surface wear',(x,y,.083),(random.uniform(.04,.31),.005,.002),SCRATCH,0);o.rotation_euler[2]=random.uniform(-.5,.5)
for x in (-4.15,4.15):
 for y in (-5.4,5.6):
  cyl('Energy lamp base',(x,y,.22),.3,.28,STEEL)
  cyl('Energy lamp',(x,y,.63),.14,.6,AMBER if x<0 else CYAN)
  for z in (.39,.57,.75):ring('Lamp cage',(x,y,z),.19,.03,EDGE)
  for dx,dy in ((.19,0),(-.19,0),(0,.19),(0,-.19)):beam('Cage rod',(x+dx,y+dy,.3),(x+dx,y+dy,.9),.02,STEEL)
  cable('Lamp cable',[(x,y,.2),(x-.4,y+.7,.14),(x+.3,y+1,.15),(x,y+1.5,.15)],DARK)
for x,y in [(-4,3.5),(4,3.5)]:
 for i in range(13):box('Physical deck',(x,y,.16+i*.047),(1.07,1.62,.04),STEEL,.02)
 box('Deck seal',(x,y,.79),(.61,.5,.018),CYAN if x<0 else RED)
box('Old display',(-3.45,-6.15,.38),(2.1,1.65,.55),STEEL)
box('Green phosphor',(-3.45,-6.15,.67),(1.65,1.1,.022),DARK)
for i in range(6):box('Telemetry',(-3.45,-6.48+i*.14,.69),(1.15-i*.1,.023,.006),CYAN)
for i in range(3):cyl('Tactile knob',(-4.15+i*.25,-5.51,.5),.075,.2,EDGE)
for y in (-6.15,6.25):
 cyl('Astra core cradle',(0,y,.3),.62,.4,STEEL)
 ring('Core socket',(0,y,.52),.51,.09,CYAN if y>0 else RED)
 orb('Contained energy',(0,y,.7),.28,CYAN if y>0 else RED)
box('Discard receptacle',(3.45,6.4,.21),(1.8,1.4,.27),STEEL)
beam('Wrench handle',(3.1,-5.9,.22),(3.8,-5.3,.22),.09,EDGE)
ring('Wrench jaw',(3.1,-5.9,.23),.18,.055,EDGE)
cable('Heavy umbilical',[(-4.7,-6,.11),(-4.9,-3,.15),(-4.75,2,.17),(-4.65,6.7,.16)],RUST,.09)
export('spark_table')
# Distinct mechanical silhouettes, designed specifically for the collectible plate portraits.
def mech(kind,hostile=False):
 light=RED if hostile else CYAN;armor=STEEL if hostile else WHITE
 if kind in ('reactor','nova'):
  orb('Spherical reactor',(0,0,1.05),.7,armor,scale=(1,.8,1))
  ring('Gyroscopic core',(0,-.48,1.1),.43,.1,EDGE,rotation=(math.pi/2,0,0))
  orb('Exposed heart',(0,-.55,1.1),.33,light)
  for angle in range(0,360,60):
   a=math.radians(angle);beam('Radial strut',(math.cos(a)*.4,math.sin(a)*.4,.65),(math.cos(a)*.95,math.sin(a)*.85,.13),.085,STEEL)
 elif kind in ('shield','tank','boss'):
  box('Heavy carapace',(0,0,.78),(1.38,1.1,.62),armor,.12)
  for sign in (-1,1):
   for y in (-.45,.45):beam('Crab leg',(sign*.48,y,.8),(sign*1.12,y*1.45,.17),.12,EDGE)
  box('Tower shield',(0,-.68,1.06),(1.65,.19,1.38),armor,.08)
  for x in (-.53,0,.53):box('Shield energy',(x,-.79,1.08),(.065,.025,1.05),light)
  if kind=='boss':
   for x in (-.7,0,.7):beam('Crown blade',(x,0,1.05),(x*1.5,0,2),.1,EDGE)
 elif kind in ('cryo','disruptor'):
  orb('Hover shell',(0,0,1.14),.55,armor,scale=(.7,.75,1.4))
  for x in (-.47,.47):
   cyl('Cryogenic canister',(x,.12,1.15),.2,.94,EDGE)
   ring('Canister light',(x,.12,1.4),.2,.04,light)
  beam('Precision lance',(0,-.2,.9),(0,-1.07,.94),.09,STEEL)
  ring('Floating stabilizer',(0,0,.27),.6,.07,light)
 elif kind in ('burst','drone','runner','ember'):
  box('Drone fuselage',(0,0,.88),(.8,1.1,.48),armor,.12)
  for x in (-.72,.72):
   box('Wing',(x,0,.85),(.75,.64,.1),EDGE)
   ring('Rotor',(x,-.13,.98),.3,.055,STEEL)
   beam('Twin weapon',(x,-.25,.65),(x,-.87,.65),.1,STEEL)
   orb('Muzzle',(x,-.89,.65),.1,light)
  box('Optical slit',(0,-.57,.97),(.45,.04,.1),light)
 elif kind in ('rail','mortar'):
  box('Tracked chassis',(0,0,.34),(1.1,1.3,.43),armor,.1)
  for x in (-.6,.6):
   box('Tread',(x,0,.29),(.25,1.5,.43),STEEL)
   for y in (-.5,0,.5):cyl('Track wheel',(x,y,.29),.17,.29,EDGE,rotation=(0,math.pi/2,0))
  orb('Turret',(0,0,.82),.42,armor)
  beam('Long accelerator',(0,0,.87),(0,-1.25,1.25 if kind=='mortar' else .87),.17,STEEL)
  ring('Accelerator coil',(0,-.69,1.08 if kind=='mortar' else .87),.2,.06,light,rotation=(math.pi/2,0,0))
 elif kind in ('repair','medic','mechanic'):
  orb('Service pod',(0,0,.8),.51,armor)
  for x in (-.53,.53):
   beam('Tool arm',(x*.65,0,.9),(x*1.5,-.4,.8),.08,EDGE)
   ring('Tool grip',(x*1.5,-.43,.84),.18,.03,light,rotation=(math.pi/2,0,0))
   cyl('Service wheel',(x,.07,.24),.3,.12,STEEL,rotation=(0,math.pi/2,0))
  box('Service cross',(0,-.48,.95),(.13,.045,.37),light)
  box('Service cross',(0,-.48,.95),(.36,.045,.13),light)
 else:
  box('Light torso',(0,0,1),(.62,.4,.65),armor,.09)
  box('Helmet',(0,-.04,1.56),(.52,.48,.42),armor,.08)
  box('Optical slit',(0,-.29,1.6),(.38,.025,.08),light)
  for x in (-.27,.27):
   beam('Shin',(x,0,.7),(x,-.03,.13),.1,EDGE)
   box('Foot',(x,-.13,.12),(.27,.42,.16),STEEL)
  beam('Right arm',(.35,0,1.25),(.64,-.35,.97),.1,EDGE)
  beam('Pulse barrel',(.64,-.3,1),(.64,-.97,1),.13,STEEL)
  orb('Pulse muzzle',(.64,-.99,1),.11,light)
  beam('Left arm',(-.35,0,1.23),(-.55,-.14,.77),.1,EDGE)
 for x in (-.18,.18):orb('Status eye',(x,-.52,1.2 if kind in ('reactor','nova') else .78),.055,light)
# Camera/lights are not exported. Collection visibility is explicit for each rendering.
bpy.ops.object.camera_add(location=(4,-7,4.3));camera=bpy.context.object;camera.name='Portrait camera';camera.rotation_euler=(Vector((0,-.05,.85))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=3.05;scene.camera=camera
for name,pos,energy,color,size in [('Soft key',(3,-4,6),850,(.82,.94,1),4),('Warm rim',(-3,2,4),1000,(1,.42,.13),3),('Cyan fill',(-3,-2,2),500,(.13,.85,1),3)]:
 bpy.ops.object.light_add(type='AREA',location=pos);o=bpy.context.object;o.name=name;o.data.energy=energy;o.data.color=color;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(Vector((0,0,.9))-o.location).to_track_quat('-Z','Y').to_euler()
for kind in ['pulse','reactor','shield','cryo','burst','rail','mortar','repair','nova','drone','runner','tank','disruptor','medic','boss']:
 start('Card machine / '+kind);mech(kind,kind in ['drone','runner','tank','disruptor','medic','boss']);export('card_'+kind)
 for c in scene.collection.children:
  if c.name not in ('Collection',collection.name):c.hide_render=True
 scene.render.filepath=str(PORTRAITS/(kind+'.png'))
 if not SKIP_PORTRAITS:bpy.ops.render.render(write_still=True)
 collection.hide_render=True
# Five distinct enemy clans, authored as geometry rather than a colour swap alone.
base_steel,base_red=STEEL,RED
clan_colors=[(.13,.31,.19),(.2,.39,.5),(.22,.12,.095),(.34,.27,.13),(.17,.12,.25)]
clan_lights=[(.34,.9,.48),(.22,.76,1),(1,.21,.045),(1,.68,.13),(.69,.3,1)]
for act in range(5):
 STEEL=mat('Clan armour '+str(act),clan_colors[act],.78,.42)
 RED=mat('Clan signal '+str(act),clan_lights[act],.2,.25,2.8)
 for kind in ['drone','runner','tank','disruptor','medic','boss']:
  name='p%d_%s'%(act,kind);start('Enemy memory / '+name);mech(kind,True)
  if act==0:
   for x in (-.52,.52):
    orb('Living moss',(x,.28,1.1),.26,STEEL,scale=(1,.7,.55))
    cable('Root conduit',[(x,0,.65),(x*1.2,.28,1),(x*.9,.36,1.4)],RED,.035)
  elif act==1:
   for x in (-.4,0,.4):
    bpy.ops.mesh.primitive_cone_add(vertices=5,radius1=.16,radius2=.02,depth=.65,location=(x,.25,1.6));finish(bpy.context.object,RED)
  elif act==2:
   for x in (-.5,.5):
    cyl('Ash chimney',(x,.26,1.24),.15,.72,STEEL)
    orb('Hot exhaust',(x,.26,1.61),.13,RED)
  elif act==3:
   for x in (-.72,.72):
    o=box('Sand fin',(x,.05,1.05),(.11,.75,.54),EDGE);o.rotation_euler[1]=-.45 if x<0 else .45
  else:
   for x in (-.66,.66):
    box('Quantum monolith',(x,.19,1.26),(.12,.22,.93),STEEL)
    box('Data filament',(x,-.035,1.26),(.045,.02,.74),RED)
  export('card_'+name)
  for c in scene.collection.children:
   if c.name not in ('Collection',collection.name):c.hide_render=True
  scene.render.filepath=str(PORTRAITS/(name+'.png'))
  if not SKIP_PORTRAITS:bpy.ops.render.render(write_still=True)
  collection.hide_render=True
STEEL,RED=base_steel,base_red
# Editable, separated collections retain all table props and original card mechs.
for i,c in enumerate(scene.collection.children):
 c.hide_render=False
 if c.name.startswith(('Card machine / ','Enemy memory / ')):
  # Clear editing library: original pieces laid out by collection after all exports.
  for o in c.objects:o.location.x+=15+(i%8)*4;o.location.y+=(i//8)*4
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'AstraTabletop.blend'))
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
print('TABLETOP COMPLETE:',len(manifest),'original GLBs and 45 card portraits')
