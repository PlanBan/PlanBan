"""Build original articulated mechs, ships and biomes in Blender 4.3+.

blender --background --factory-startup --python tools/generate_models.py
Exports real skinned GLBs with Idle, Walk, Attack, Deploy and Death clips;
the editable .blend library is stored beside the Godot project.
"""
from pathlib import Path
import bpy, math, random, json
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets3d'
ICONS = OUT / 'icons'
SOURCE = ROOT.parent / 'OrbitGuardians-Blender'
for path in [OUT, ICONS, SOURCE]: path.mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for block in list(bpy.data.collections):
    if block.name != 'Collection': bpy.data.collections.remove(block)
scene = bpy.context.scene
scene.render.fps = 30
scene.render.engine = 'CYCLES'
scene.cycles.samples = 96
scene.cycles.use_denoising = False
scene.render.threads_mode = 'FIXED'
scene.render.threads = 4
scene.render.resolution_x = scene.render.resolution_y = 256
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
scene.view_settings.view_transform = 'AgX'
scene.world.color = (.09, .09, .09)
random.seed(8146)
manifest = {}
active_collection = None
rig = None
pieces = []

def material(name, color, metal=.65, rough=.32, emission=0):
    result = bpy.data.materials.new(name)
    result.diffuse_color = (*color, 1)
    result.use_nodes = True
    node = result.node_tree.nodes.get('Principled BSDF')
    node.inputs['Base Color'].default_value = (*color, 1)
    node.inputs['Metallic'].default_value = metal
    node.inputs['Roughness'].default_value = rough
    if emission:
        node.inputs['Emission Color'].default_value = (*color, 1)
        node.inputs['Emission Strength'].default_value = emission
    return result

STEEL = material('Titanium / dark joints', (.075, .095, .13), .85, .27)
WHITE = material('Ceramic / moon ivory', (.64, .74, .78), .55, .28)
BLUE = material('Armor / midnight blue', (.075, .16, .24), .72, .29)
TRIM = material('Machined edge', (.27, .37, .44), .85, .22)
CYAN = material('Astra / cyan light', (.12, .82, 1.0), .25, .22, 3.0)
ORANGE = material('Reactor / amber light', (1.0, .49, .075), .2, .25, 2.5)
BLACK = material('Visor / obsidian', (.009, .02, .035), .62, .19)
RED = material('Hostile / crimson light', (1.0, .08, .035), .35, .2, 3.0)

def collection(name):
    global active_collection, pieces, rig
    active_collection = bpy.data.collections.new(name)
    scene.collection.children.link(active_collection)
    pieces = []; rig = None
    return active_collection

def move(obj):
    for owner in list(obj.users_collection): owner.objects.unlink(obj)
    active_collection.objects.link(obj)
    return obj

def finish(obj, mat, bone='Body'):
    move(obj)
    obj.data.materials.append(mat)
    if rig:
        obj.parent = rig
        group = obj.vertex_groups.new(name=bone)
        group.add(list(range(len(obj.data.vertices))), 1, 'REPLACE')
        modifier = obj.modifiers.new('Rigid mech skin', 'ARMATURE')
        modifier.object = rig
    pieces.append(obj)
    return obj

def box(name, pos, size, mat, bone='Body', bevel=.055):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
    obj = bpy.context.object; obj.name = name
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        modifier = obj.modifiers.new('Machined bevel', 'BEVEL')
        modifier.width = min(bevel, min(size)*.22); modifier.segments = 2
        bpy.ops.object.modifier_apply(modifier=modifier.name)
        for polygon in obj.data.polygons: polygon.use_smooth = True
        modifier = obj.modifiers.new('Weighted normals', 'WEIGHTED_NORMAL')
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    return finish(obj, mat, bone)

def sphere(name, pos, radius, mat, bone='Body', scale=(1,1,1)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=radius, location=pos)
    obj=bpy.context.object; obj.name=name; obj.scale=scale
    for p in obj.data.polygons:p.use_smooth=True
    return finish(obj,mat,bone)

def cylinder(name,pos,radius,depth,mat,bone='Body',rotation=(0,0,0),verts=20):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=radius,depth=depth,location=pos,rotation=rotation)
    obj=bpy.context.object;obj.name=name
    modifier=obj.modifiers.new('Rounded rim','BEVEL');modifier.width=.025;modifier.segments=2
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    for p in obj.data.polygons:p.use_smooth=True
    modifier=obj.modifiers.new('Weighted normals','WEIGHTED_NORMAL');bpy.ops.object.modifier_apply(modifier=modifier.name)
    return finish(obj,mat,bone)

def cone(name,pos,radius,depth,mat,rotation=(0,0,0),bone='Body'):
    bpy.ops.mesh.primitive_cone_add(vertices=6,radius1=radius,radius2=.015,depth=depth,location=pos,rotation=rotation)
    obj=bpy.context.object;obj.name=name
    return finish(obj,mat,bone)

def beam(name,a,b,radius,mat,bone='Body'):
    a,b=Vector(a),Vector(b)
    obj=cylinder(name,(a+b)/2,radius,(b-a).length,mat,bone)
    obj.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
    return obj

def armature(name):
    global rig
    bpy.ops.object.armature_add(enter_editmode=True)
    rig=bpy.context.object;rig.name=name+'_Rig';move(rig)
    bones=rig.data.edit_bones
    bones.remove(bones[0])
    specs={'Root':((0,0,0),(0,0,.35),None), 'Body':((0,0,1.2),(0,0,1.8),'Root'),
           'Head':((0,0,2),(0,0,2.4),'Body')}
    for side,x in [('L',-.29),('R',.29)]:
        specs['Thigh.'+side]=((x,0,1.15),(x,0,.62),'Root')
        specs['Shin.'+side]=((x,0,.62),(x,-.06,.16),'Thigh.'+side)
        specs['Foot.'+side]=((x,-.06,.16),(x,-.40,.16),'Shin.'+side)
        sign=-1 if side=='L' else 1
        specs['Arm.'+side]=((sign*.62,0,1.90),(sign*.76,0,1.46),'Body')
        specs['Fore.'+side]=((sign*.76,0,1.46),(sign*.76,-.34,1.44),'Arm.'+side)
    for key,(head,tail,parent) in specs.items():
        b=bones.new(key);b.head=head;b.tail=tail
        if parent:b.parent=bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT')
    for b in rig.pose.bones:b.rotation_mode='XYZ'
    return rig

def neutral():
    for b in rig.pose.bones:
        b.location=(0,0,0);b.rotation_euler=(0,0,0);b.scale=(1,1,1)

def animate(name):
    rig.animation_data_create()
    for title,length in [('Idle',72),('Walk',30),('Attack',24),('Deploy',42),('Death',48)]:
        action=bpy.data.actions.new(name+'_'+title)
        rig.animation_data.action=action
        for frame in sorted(set([1, int(length*.25), int(length*.5), int(length*.75), length])):
            neutral();t=(frame-1)/(length-1)
            b=rig.pose.bones
            if title=='Idle':
                b['Body'].location.y=.025*math.sin(t*math.tau)
                b['Head'].rotation_euler.y=.11*math.sin(t*math.tau)
                b['Fore.L'].rotation_euler.x=.04*math.sin(t*math.tau)
            elif title=='Walk':
                step=math.sin(t*math.tau)
                b['Thigh.L'].rotation_euler.x=step*.48;b['Thigh.R'].rotation_euler.x=-step*.48
                b['Shin.L'].rotation_euler.x=max(0,-step)*.66;b['Shin.R'].rotation_euler.x=max(0,step)*.66
                b['Arm.L'].rotation_euler.x=-step*.24;b['Arm.R'].rotation_euler.x=step*.24
                b['Body'].location.y=.055*(1-math.cos(t*math.tau*2))
                b['Body'].rotation_euler.y=step*.055
            elif title=='Attack':
                kick=math.sin(t*math.pi)**2
                b['Fore.R'].rotation_euler.x=-kick*.48
                b['Arm.L'].rotation_euler.x=-kick*.18
                b['Body'].rotation_euler.x=kick*.10
                b['Body'].location.y=-kick*.035
            elif title=='Deploy':
                unfold=min(1,t*2.4)
                s=.05+.95*unfold
                b['Root'].scale=(s,s,s)
                b['Body'].location.y=.13*math.sin(t*math.pi)
                b['Arm.L'].rotation_euler.z=(1-unfold)*.85
                b['Arm.R'].rotation_euler.z=-(1-unfold)*.85
                b['Thigh.L'].rotation_euler.x=(1-unfold)*.65
                b['Thigh.R'].rotation_euler.x=(1-unfold)*.65
            else:
                fall=min(1,t*1.5)
                b['Root'].rotation_euler.x=fall*1.28
                b['Body'].rotation_euler.x=fall*.2
                b['Shin.L'].rotation_euler.x=fall*.65
                b['Shin.R'].rotation_euler.x=fall*.8
                b['Arm.L'].rotation_euler.z=fall*.38
                b['Arm.R'].rotation_euler.z=-fall*.3
            for bone in b:
                bone.keyframe_insert('location',frame=frame)
                bone.keyframe_insert('rotation_euler',frame=frame)
                bone.keyframe_insert('scale',frame=frame)
        rig.animation_data.action=None
        track=rig.animation_data.nla_tracks.new();track.name=title
        strip=track.strips.new(title,1,action);strip.extrapolation='NOTHING'
        strip.blend_type='REPLACE'
    neutral();scene.frame_set(0)

def merge(name):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in pieces:obj.select_set(True)
    bpy.context.view_layer.objects.active=pieces[0]
    bpy.ops.object.join()
    obj=bpy.context.object;obj.name=name+'_Mesh'
    return obj

def export(name,thumb=False):
    mesh=merge(name)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in active_collection.objects:obj.select_set(True)
    bpy.context.view_layer.objects.active=rig or mesh
    scene.frame_set(0)
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,
        export_animation_mode='NLA_TRACKS',export_frame_range=False,export_anim_single_armature=False,
        export_skins=True,export_yup=True,export_apply=False,export_cameras=False,export_lights=False)
    manifest[name]={'file':name+'.glb','vertices':len(mesh.data.vertices),'animations':['Idle','Walk','Attack','Deploy','Death'] if rig else []}
    if thumb:thumbnail(name)
    # Lay out the editable Blender library after exporting local origin models.
    index=len(manifest)-1
    offset=Vector(((index%8)*5,(index//8)*6,0))
    if rig:rig.location+=offset
    else:mesh.location+=offset
    print('ASSET READY',name,flush=True)

def thumbnail(name):
    old_hidden={c:c.hide_render for c in scene.collection.children}
    for c in scene.collection.children:c.hide_render=c!=active_collection
    studio=bpy.data.collections.new('Temporary thumbnail studio');scene.collection.children.link(studio)
    def studio_obj(obj):
        for c in list(obj.users_collection):c.objects.unlink(obj)
        studio.objects.link(obj)
        return obj
    bpy.ops.object.camera_add(location=(3.7,-5.8,3.15))
    camera=studio_obj(bpy.context.object);camera.data.type='ORTHO';camera.data.ortho_scale=3.25
    camera.rotation_euler=(Vector((0,-.1,1.25))-camera.location).to_track_quat('-Z','Y').to_euler()
    scene.camera=camera
    for location,power,color,size in [((3,-4,6),620,(.78,.88,1),4),((-3,-2,3),380,(.3,.85,1),3),((1,3,5),850,(1,.69,.4),3)]:
        bpy.ops.object.light_add(type='AREA',location=location)
        light=studio_obj(bpy.context.object);light.data.energy=power;light.data.color=color;light.data.shape='DISK';light.data.size=size
        light.rotation_euler=(Vector((0,0,1))-light.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(ICONS/(name+'.png'))
    bpy.ops.render.render(write_still=True)
    for obj in list(studio.objects):bpy.data.objects.remove(obj,do_unlink=True)
    bpy.data.collections.remove(studio)
    for c,hidden in old_hidden.items():c.hide_render=hidden

def humanoid(name,armor,light,hostile=False,bulky=False):
    armature(name)
    chest=(1.04,.58,.64) if bulky else (.87,.48,.60)
    box('Segmented chest',(0,0,1.67),chest,armor)
    box('Raised breastplate',(0,-.29,1.69),(.67,.14,.38),TRIM)
    box('Chest light',(0,-.378,1.74),(.38,.035,.065),light)
    cylinder('Astra core',(0,-.375,1.49),.13,.045,light,rotation=(math.pi/2,0,0))
    box('Spine backpack',(0,.34,1.66),(.60,.26,.65),BLUE if not hostile else STEEL)
    for x in [-.19,.19]:box('Cooling fin',(x,.495,1.69),(.05,.04,.42),TRIM)
    box('Pelvis',(0,0,1.15),(.67,.42,.26),STEEL,'Root')
    box('Waist armor',(0,-.19,1.19),(.54,.14,.23),armor,'Root')
    box('Helmet',(0,-.02,2.18),(.64,.49,.39),armor,'Head',.08)
    box('Recessed visor',(0,-.283,2.21),(.53,.055,.17),BLACK,'Head',.035)
    for x in [-.135,.135]:box('Optic',(x,-.32,2.23),(.12,.022,.044),light,'Head',.01)
    box('Jaw plate',(0,-.245,2.06),(.34,.06,.07),TRIM,'Head')
    for side,sign in [('L',-1),('R',1)]:
        x=sign*.29
        sphere('Hip joint',(x,0,1.10),.135,STEEL,'Thigh.'+side)
        box('Thigh armor',(x,0,.90),(.31,.36,.42),armor,'Thigh.'+side)
        sphere('Knee hinge',(x,-.025,.62),.135,TRIM,'Shin.'+side)
        box('Shin armor',(x,0,.38),(.32,.32,.37),armor,'Shin.'+side)
        box('Shin inset',(x,-.18,.41),(.16,.045,.15),BLUE,'Shin.'+side)
        box('Magnetic boot',(x,-.14,.13),(.38,.60,.23),STEEL,'Foot.'+side)
        box('Toe cap',(x,-.40,.16),(.33,.17,.11),armor,'Foot.'+side)
        sphere('Shoulder bearing',(sign*.58,0,1.88),.16,STEEL,'Arm.'+side)
        box('Shoulder plate',(sign*.65,0,1.97),(.34,.49,.24),armor,'Arm.'+side)
        box('Upper arm',(sign*.75,0,1.66),(.23,.25,.31),TRIM,'Arm.'+side)
        sphere('Elbow bearing',(sign*.76,0,1.46),.12,STEEL,'Fore.'+side)
        box('Forearm gauntlet',(sign*.76,-.18,1.44),(.26,.41,.25),armor,'Fore.'+side)
        box('Gauntlet light',(sign*.902,-.17,1.47),(.022,.17,.045),light,'Fore.'+side)

def weapon(kind,light=CYAN):
    bone='Fore.R'
    if kind in ['pulse','cryo','rail','burst','mortar']:
        length=.94 if kind=='rail' else .63
        box('Weapon housing',(.76,-.45,1.48),(.31,length,.25),BLUE,bone)
        cylinder('Muzzle barrel',(.76,-.87 if kind!='rail' else -1.02,1.49),.09,.26,TRIM,bone,(math.pi/2,0,0))
        cylinder('Muzzle emitter',(.76,-1.012 if kind!='rail' else -1.16,1.49),.067,.025,light,bone,(math.pi/2,0,0))
        for i in range(3):box('Coil segment',(.76,-.40-i*.12,1.62),(.29,.03,.035),light,bone,.008)
        if kind=='burst':
            cylinder('Second barrel',(.76,-.9,1.30),.08,.26,TRIM,bone,(math.pi/2,0,0))
            cylinder('Second emitter',(.76,-1.04,1.3),.055,.025,ORANGE,bone,(math.pi/2,0,0))
        if kind=='mortar':
            cylinder('Back-mounted launcher',(-.28,.34,2.0),.18,.62,TRIM,'Body',(-.45,0,0))
            cylinder('Mortar shell',(-.28,.19,2.32),.14,.08,ORANGE,'Body',(-.45,0,0))
    elif kind=='shield':
        box('Shield frame',(-.81,-.46,1.27),(.88,.19,1.23),TRIM,'Fore.L',.085)
        box('Shield ceramic',(-.81,-.575,1.29),(.75,.09,1.09),WHITE,'Fore.L',.065)
        for x in [-1.05,-.80,-.55]:box('Shield charge rail',(x,-.633,1.28),(.042,.026,.87),ORANGE,'Fore.L',.008)
    elif kind=='repair':
        box('Repair tool',(.76,-.51,1.47),(.32,.32,.22),STEEL,bone)
        for x in [.63,.89]:beam('Tool claw',(x,-.61,1.48),(x,-.88,1.57),.038,TRIM,bone)
        box('Medical cross vertical',(0,-.395,1.7),(.045,.02,.21),light)
        box('Medical cross horizontal',(0,-.395,1.7),(.18,.02,.045),light)
    elif kind=='nova':
        sphere('Singularity',(0,-.35,1.6),.26,light,scale=(1,.56,1))
        for i in range(6):
            angle=i*math.tau/6
            sphere('Core stabilizer',(.34*math.cos(angle),-.36,1.6+.34*math.sin(angle)),.065,TRIM)

def friendly(kind):
    collection(kind)
    accent={'reactor':ORANGE,'burst':ORANGE,'shield':ORANGE}.get(kind,CYAN)
    if kind=='nova':accent=material('Nova plasma',(.69,.20,1),.2,.3,3)
    if kind=='repair':accent=material('Repair green',(.24,1,.62),.25,.3,2)
    if kind=='cryo':accent=material('Cryo white',(.5,.85,1),.2,.2,3)
    if kind=='rail':accent=material('Rail violet',(.65,.42,1),.25,.3,3)
    humanoid(kind,WHITE,accent)
    if kind=='reactor':
        box('Generator casing',(0,-.06,1.61),(.99,.70,.82),BLUE,bevel=.09)
        cylinder('Contained power cell',(0,-.46,1.66),.29,.11,ORANGE,rotation=(math.pi/2,0,0))
        cylinder('Metallic collar',(0,-.39,1.66),.36,.08,TRIM,rotation=(math.pi/2,0,0))
        for x in [-.53,.53]:
            cylinder('Capacitor',(x,0,1.55),.14,.65,TRIM)
            box('Capacitor glow',(x,-.155,1.55),(.045,.025,.38),ORANGE)
    else:weapon(kind,accent)
    animate(kind);export(kind,True)

def enemy(kind,biome=None):
    name=kind if biome is None else f'p{biome}_{kind}'
    collection(name)
    palettes=[(.10,.27,.21),(.34,.55,.69),(.30,.12,.09),(.49,.36,.18),(.20,.14,.33)]
    armor=material(name+' armor',palettes[biome] if biome is not None else (.20,.25,.32),.7,.34)
    light=RED if biome not in [1,4] else material(name+' plasma',(.35,.80,1) if biome==1 else (.74,.22,1),.3,.25,3)
    humanoid(name,armor,light,True,kind in ['tank','boss'])
    if kind in ['drone','runner']:weapon('pulse',light)
    if kind=='tank':
        for x in [-.67,.67]:box('Heavy shoulder',(x,0,1.99),(.49,.62,.45),armor,'Arm.L' if x<0 else 'Arm.R')
        box('Tank breastplate',(0,-.43,1.59),(.91,.19,.54),armor)
    if kind=='disruptor':
        for x in [-.3,.3]:
            cylinder('EMP antenna',(x,.29,2.18),.04,.75,TRIM)
            sphere('EMP charge',(x,.29,2.58),.11,light)
    if kind=='medic':
        box('Support battery',(0,.52,1.62),(.77,.25,.58),armor)
        weapon('repair',material(name+' healing',(.19,1,.46),.2,.3,2))
    if kind=='boss':
        for x in [-.64,.64]:box('Commander pauldron',(x,0,2.06),(.54,.65,.42),armor,'Arm.L' if x<0 else 'Arm.R')
        for x in [-.25,0,.25]:cone('Crown spike',(x,0,2.60),.11,.48,TRIM,bone='Head')
        box('Commander blade',(.76,-.62,1.49),(.16,.96,.33),light,'Fore.R',.02)
    if biome==0:
        moss=material(name+' moss',(.12,.42,.19),.05,.85)
        for x in [-.42,.35]:sphere('Overgrowth',(x,.08,1.89),.19,moss,scale=(1,1,.55))
        beam('Vine',(-.4,-.30,1.89),(.20,-.34,1.43),.032,moss)
    elif biome==1:
        for x in [-.45,.45]:cone('Crystal shoulder',(x,0,2.13),.17,.62,light,rotation=(0,x*.8,0))
        cone('Ice back spike',(0,.43,1.9),.2,.70,light,rotation=(.4,0,0))
    elif biome==2:
        for x in [-.35,.35]:cone('Volcanic horn',(x,0,2.43),.13,.51,armor,rotation=(0,x*.7,0),bone='Head')
        for x in [-.3,.3]:box('Molten crack',(x,-.4,1.68),(.035,.025,.34),light)
    elif biome==3:
        box('Sand carapace',(0,.2,1.85),(1.07,.77,.24),armor,bevel=.1)
        for x in [-.51,.51]:cone('Scarab thorn',(x,.22,1.86),.11,.51,TRIM,rotation=(0,math.pi/2,0))
    elif biome==4:
        for x in [-.42,.42]:sphere('Quantum node',(x,.1,1.96),.11,light)
        box('Nexus crown',(0,.12,2.4),(.80,.10,.11),light,'Head')
    animate(name);export(name,biome is None or kind=='boss')

def spaceship(name,hostile=False):
    collection(name)
    armor=material(name+' hull',(.12,.16,.23) if hostile else (.34,.43,.52),.8,.26)
    glow=RED if hostile else CYAN
    box('Main fuselage',(0,0,0),(1.45,4.4,.65),armor,bevel=.13)
    box('Upper hull',(0,-.7,.38),(1.12,2.2,.43),armor,bevel=.12)
    # Tapered nose and wings built as actual meshes.
    verts=[(-.68,-1.8,-.23),(.68,-1.8,-.23),(0,-3.5,0),(-.52,-1.8,.44),(.52,-1.8,.44),(0,-3.2,.18)]
    mesh=bpy.data.meshes.new('Nose');mesh.from_pydata(verts,[],[(0,1,2),(3,5,4),(0,3,4,1),(1,4,5,2),(2,5,3,0)])
    obj=bpy.data.objects.new('Swept nose',mesh);active_collection.objects.link(obj);finish(obj,armor)
    for side in [-1,1]:
        verts=[(side*.5,-.9,0),(side*3.2,1.5,-.18),(side*2.7,2.25,-.2),(side*.7,1.8,.1),(side*.55,-.9,.2),(side*3.15,1.5,.04),(side*2.65,2.25,.05),(side*.7,1.8,.3)]
        mesh=bpy.data.meshes.new('Wing');mesh.from_pydata(verts,[],[(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)])
        obj=bpy.data.objects.new('Swept wing',mesh);active_collection.objects.link(obj);finish(obj,armor)
        box('Wing light',(side*1.65,1.6,.17),(1.45,.09,.05),glow)
        cylinder('Engine',(side*.73,1.65,-.05),.30,1.17,STEEL,rotation=(math.pi/2,0,0))
        cylinder('Thruster',(side*.73,2.25,-.05),.24,.05,glow,rotation=(math.pi/2,0,0))
        box('Stabilizer',(side*.74,1.72,.48),(.12,.91,.71),armor)
    box('Cockpit glass',(0,-1.12,.59),(.64,1.16,.15),BLACK,bevel=.05)
    box('Cockpit reflection',(0,-1.20,.677),(.49,.67,.02),glow,bevel=.01)
    for i in range(4):box('Hull vent',(0,.13+i*.30,.36),(.82,.06,.045),TRIM)
    export(name)

def terrain(name,biome):
    collection(name)
    colors=[(.16,.27,.19),(.47,.64,.71),(.14,.12,.13),(.54,.42,.26),(.075,.075,.14)]
    ground=material(name+' surface',colors[biome],.05 if biome!=4 else .7,.84 if biome!=4 else .35)
    edge=material(name+' stone',tuple(c*.65 for c in colors[biome]),.18,.8)
    glow=material(name+' accent',[(.33,.66,.3),(.28,.76,1),(1,.23,.025),(.8,.53,.18),(.46,.15,1)][biome],.25,.4,1.5 if biome>1 else .3)
    verts=[];faces=[]
    for y in range(21):
        for x in range(29):
            px=x-14;py=(y-10)*.7
            border=abs(px)>9.2 or abs(py)>4.8
            height=random.uniform(-.1,.12) if not border else random.uniform(.0,.48)
            verts.append((px,py,height-.10))
    for y in range(20):
        for x in range(28):
            a=y*29+x;faces.extend([(a,a+1,a+30),(a,a+30,a+29)])
    mesh=bpy.data.meshes.new(name+' ground');mesh.from_pydata(verts,[],faces)
    obj=bpy.data.objects.new('Landscape',mesh);active_collection.objects.link(obj);finish(obj,ground)
    for i in range(30):
        x=random.choice([-1,1])*random.uniform(10.3,13.2);y=random.uniform(-6.4,6.4)
        if biome==0:
            cylinder('Tree trunk',(x,y,.65),.17,1.3,edge,verts=8)
            for z,r in [(1.2,.8),(1.9,.66),(2.5,.42)]:cone('Evergreen canopy',(x,y,z),r,1.1,ground)
            sphere('Forest rock',(x+1,y+.5,.25),.5,edge,scale=(1,.8,.65))
        elif biome==1:
            for j in range(3):cone('Glacial shard',(x+j*.3,y,.75+j*.2),.4,.9+j*.6,glow,rotation=(.08,.18*j,0))
            sphere('Snow drift',(x,y+.5,.25),.9,ground,scale=(1.3,1,.3))
        elif biome==2:
            cylinder('Basalt column',(x,y,.65),.55,1.3,edge,verts=6)
            box('Lava fissure',(x+.62,y,.0),(.15,random.uniform(.8,2),.07),glow,bevel=.02)
        elif biome==3:
            cylinder('Ruined pillar',(x,y,.68),.32,1.4,edge,verts=8)
            box('Ruin cap',(x,y,1.38),(.8,.8,.14),ground)
            sphere('Sand dune',(x,y+.6,.1),1,ground,scale=(1.5,1,.28))
        else:
            box('Machine monolith',(x,y,1),(1,1,2),edge)
            box('Circuit face',(x,y-.53,1),(.06,.04,1.4),glow)
            sphere('Signal node',(x,y,2.2),.15,glow)
    if biome==4:
        box('Floating foundation',(0,0,-.65),(20,11,.95),edge,bevel=.25)
        for x in [-9.7,9.7]:box('Foundation rails',(x,0,-.12),(.08,10.8,.08),glow)
    export(name)

for kind in ['pulse','reactor','shield','cryo','burst','rail','mortar','repair','nova']:friendly(kind)
for kind in ['drone','runner','tank','disruptor','medic','boss']:enemy(kind)
for biome in range(5):
    for kind in ['drone','runner','tank','disruptor','medic','boss']:enemy(kind,biome)
spaceship('ship');spaceship('carrier',True)
for biome,name in enumerate(['forest','ice','lava','desert','void']):terrain('terrain_'+name,biome)
collection('core')
sphere('Contained Astra plasma',(0,0,0),.45,CYAN)
for axis in range(3):
    bpy.ops.mesh.primitive_torus_add(major_radius=.65,minor_radius=.055,major_segments=36,minor_segments=8,rotation=(math.pi/2 if axis==0 else 0,math.pi/2 if axis==1 else 0,0))
    finish(bpy.context.object,TRIM)
export('core')
collection('planet')
bpy.ops.mesh.primitive_uv_sphere_add(segments=64,ring_count=32,radius=1)
obj=bpy.context.object
for p in obj.data.polygons:p.use_smooth=True
finish(obj,WHITE);export('planet')
scene.frame_set(0)
OUT.joinpath('manifest.json').write_text(json.dumps(manifest,indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'AstraLibrary.blend'))
print('BLENDER BUILD COMPLETE:',len(manifest),'original GLB assets',flush=True)
