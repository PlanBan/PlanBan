"""Original miniature worlds, machinery and route props, built in Blender.

blender --background --factory-startup --python tools/generate_dioramas.py
All geometry and PBR textures are generated here; no downloaded art or models.
Static meshes are batched by material. Editable collections remain in the .blend.
"""
from pathlib import Path
import bpy, numpy as np, math, random, json
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets3d' / 'diorama'
SOURCE = ROOT.parent / 'OrbitGuardians-Blender'
OUT.mkdir(parents=True, exist_ok=True)
SOURCE.mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 48
scene.cycles.use_denoising = False
scene.render.threads_mode = 'FIXED'
scene.render.threads = 4
scene.view_settings.view_transform = 'AgX'
manifest = {}

def texture(name, base, metal=False):
    """Baked mottling, machining grain, scratches and oxidation, with real UVs."""
    rng = np.random.default_rng(101 + sum(map(ord, name)))
    n = 512 if metal else 256
    yy, xx = np.mgrid[0:n, 0:n]
    broad = np.zeros((n, n))
    for size, weight in [(8, .12), (32, .065), (128, .025)]:
        tile = rng.random((size, size)) - .5
        row = np.array([np.interp(np.linspace(0,size-1,n),np.arange(size),line) for line in tile])
        smooth = np.array([np.interp(np.linspace(0,size-1,n),np.arange(size),line) for line in row.T]).T
        broad += smooth * weight
    fine = (rng.random((n, n)) - .5) * .045
    noise = broad + fine
    if metal:
        noise += .018 * np.sin(yy * 2.4)
        scratches = (rng.random((n, n)) > .997).astype(float)
        for dx in range(1, 9): scratches += np.roll(scratches, dx, 1) * (1 - dx / 10)
        noise += scratches * .12
    rgba = np.ones((n, n, 4), dtype=np.float32)
    rgba[:, :, :3] = np.clip(np.array(base)[None, None, :] * (1 + noise[:, :, None] * 3), .008, .98)
    im = bpy.data.images.new(name + ' / albedo', width=n, height=n)
    im.pixels.foreach_set(rgba.ravel()); im.pack()
    return im

def mat(name, color, metal=0, rough=.75, glow=0, textured=False):
    m = bpy.data.materials.new(name); m.diffuse_color = (*color, 1); m.use_nodes = True
    node = m.node_tree.nodes.get('Principled BSDF')
    node.inputs['Base Color'].default_value = (*color, 1)
    node.inputs['Metallic'].default_value = metal
    node.inputs['Roughness'].default_value = rough
    if glow:
        node.inputs['Emission Color'].default_value = (*color, 1)
        node.inputs['Emission Strength'].default_value = glow
    if textured:
        tex = m.node_tree.nodes.new('ShaderNodeTexImage'); tex.image = texture(name, color, metal > .2)
        m.node_tree.links.new(tex.outputs['Color'], node.inputs['Base Color'])
    return m

STEEL = mat('Diorama / worn graphite', (.075, .085, .10), .85, .38, textured=True)
COPPER = mat('Diorama / burnished copper', (.31, .155, .07), .8, .35, textured=True)
EDGE = mat('Diorama / machined titanium', (.36, .39, .40), .9, .3, textured=True)
DARK = mat('Diorama / rubber recess', (.009, .016, .021), .2, .65)
CERAMIC = mat('Diorama / ivory armour', (.74, .77, .72), .5, .28)
CYAN = mat('Diorama / cyan phosphor', (.015, .75, .95), .3, .25, 3)
ORANGE = mat('Diorama / amber phosphor', (1, .10, .005), .25, .28, 1.4)
RED = mat('Diorama / hostile phosphor', (1, .035, .008), .2, .3, 1.7)

class Batch:
    def __init__(self, name):
        self.name = name; self.v = []; self.f = []; self.mi = []; self.mats = []
    def poly(self, vertices, faces, material):
        offset = len(self.v); self.v.extend(vertices)
        if material not in self.mats: self.mats.append(material)
        idx = self.mats.index(material)
        self.f.extend(tuple(i + offset for i in face) for face in faces)
        self.mi.extend([idx] * len(faces))
    def box(self, p, s, m, rz=0):
        x, y, z = p; a, b, c = [i / 2 for i in s]; co, si = math.cos(rz), math.sin(rz)
        vertices = [(x + dx*co - dy*si, y + dx*si + dy*co, z + dz)
                    for dx, dy, dz in [(-a,-b,-c),(a,-b,-c),(a,b,-c),(-a,b,-c),(-a,-b,c),(a,-b,c),(a,b,c),(-a,b,c)]]
        self.poly(vertices, [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)], m)
    def cone(self, p, r, h, m, top=0, n=10):
        x, y, z = p
        vertices = [(x + rr*math.cos(i*math.tau/n), y + rr*math.sin(i*math.tau/n), z + zz)
                    for rr, zz in [(r, -h/2), (top, h/2)] for i in range(n)]
        self.poly(vertices, [tuple(reversed(range(n))), tuple(range(n,2*n))] +
                  [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)], m)
    def torus(self, p, r, tube, m, n=40, sides=6):
        x, y, z = p
        vertices = [(x+(r+tube*math.cos(j*math.tau/sides))*math.cos(i*math.tau/n),
                     y+(r+tube*math.cos(j*math.tau/sides))*math.sin(i*math.tau/n),
                     z+tube*math.sin(j*math.tau/sides)) for i in range(n) for j in range(sides)]
        faces = [(i*sides+j,((i+1)%n)*sides+j,((i+1)%n)*sides+(j+1)%sides,i*sides+(j+1)%sides)
                 for i in range(n) for j in range(sides)]
        self.poly(vertices, faces, m)
    def beam(self, a, b, width, m, n=8):
        a, b = Vector(a), Vector(b); axis = b-a
        cross = axis.normalized().cross(Vector((0,0,1)))
        if cross.length < .01: cross = Vector((1,0,0))
        cross.normalize(); other = axis.normalized().cross(cross)
        vertices = [tuple(p + width*(math.cos(i*math.tau/n)*cross+math.sin(i*math.tau/n)*other))
                    for p in (a,b) for i in range(n)]
        self.poly(vertices, [tuple(reversed(range(n))), tuple(range(n,2*n))] +
                  [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)], m)
    def rock(self, p, s, m, rng):
        x,y,z = p; a,b,c = s
        vertices = []
        for layer in range(3):
            for i in range(7):
                angle = i*math.tau/7
                radius = rng.uniform(.7,1.1) * (.82 if layer == 2 else 1)
                vertices.append((x+math.cos(angle)*a*radius,y+math.sin(angle)*b*radius,z+layer*c*.5+rng.uniform(-.09,.09)*c))
        faces = [tuple(reversed(range(7))),tuple(range(14,21))]
        faces += [(layer*7+i,layer*7+(i+1)%7,(layer+1)*7+(i+1)%7,(layer+1)*7+i) for layer in range(2) for i in range(7)]
        self.poly(vertices, faces, m)
    def object(self, collection):
        mesh = bpy.data.meshes.new(self.name); mesh.from_pydata(self.v, [], self.f); mesh.update()
        for m in self.mats: mesh.materials.append(m)
        for polygon, idx in zip(mesh.polygons, self.mi): polygon.material_index = idx
        # UV projection follows the face normal, so vertical cliffs and metal rails have grain too.
        uv = mesh.uv_layers.new(name='Baked detail UV')
        for polygon in mesh.polygons:
            normal = polygon.normal; axis = max(range(3), key=lambda i: abs(normal[i]))
            components = [i for i in range(3) if i != axis]
            for li in polygon.loop_indices:
                co = mesh.vertices[mesh.loops[li].vertex_index].co
                uv.data[li].uv = (co[components[0]]*.6,co[components[1]]*.6)
        obj = bpy.data.objects.new(self.name, mesh); collection.objects.link(obj); return obj

def collection(name):
    c = bpy.data.collections.new(name); scene.collection.children.link(c); return c

def export(name, c, animated=False):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in c.objects: obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')), export_format='GLB', use_selection=True,
                              export_yup=True, export_animations=animated,
                              export_animation_mode='NLA_TRACKS',export_frame_range=False,
                              export_skins=True,export_anim_single_armature=False)
    manifest[name] = {'vertices':sum(len(o.data.vertices) for o in c.objects if o.type=='MESH'),
                      'triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in c.objects if o.type=='MESH')}

def height(x,y):
    # Broad natural undulations and a stepped western ravine; route sockets sit on real terrain.
    h = .38+.10*math.sin(x*2.7+y*.8)+.075*math.cos(y*2.4-x)
    if x < -3.25: h += .32*math.floor((y+6.4)/3.1)
    h += .25*max(0,abs(x)-3.7)
    return h

def node_position(depth, col):
    x = (col-1)*2.6 + (0 if depth in (0,6) else [.10,-.18,.18,-.12,.08][depth-1])
    y = -4.85+depth*1.59
    return x,y,height(x,y)+.11

def near_route(x,y):
    for d in range(7):
        for col in ([1] if d in (0,6) else [0,1,2]):
            nx,ny,_ = node_position(d,col)
            if math.hypot(x-nx,y-ny)<.72: return True
    # Carve every genuine adjacent-column link into the miniature's scattered vegetation.
    for d in range(6):
        for col in ([1] if d==0 else [0,1,2]):
            for nxt in ([1] if d==5 else [0,1,2]):
                if d not in (0,5) and abs(col-nxt)>1:continue
                ax,ay,_=node_position(d,col);bx,by,_=node_position(d+1,nxt)
                dx,dy=bx-ax,by-ay
                t=max(0,min(1,((x-ax)*dx+(y-ay)*dy)/(dx*dx+dy*dy)))
                if math.hypot(x-ax-t*dx,y-ay-t*dy)<.20:return True
    return abs(x)<.16 and y<-4.8

def paint_terrain(act, material):
    """Unique baked soil/grass/snow, worn paths and small surface detail for each world."""
    n=1024;rng=np.random.default_rng(93017+act)
    yy,xx=np.mgrid[0:n,0:n];x=-4.65+xx*9.3/(n-1);y=-6.35+yy*12.7/(n-1)
    noise=np.zeros((n,n))
    for size,amount in [(10,.16),(38,.08),(120,.035)]:
        grid=rng.random((size,size))-.5
        row=np.array([np.interp(np.linspace(0,size-1,n),np.arange(size),line) for line in grid])
        smooth=np.array([np.interp(np.linspace(0,size-1,n),np.arange(size),line) for line in row.T]).T
        noise+=smooth*amount
    noise+=(rng.random((n,n))-.5)*.025
    colors=[(.065,.105,.037),(.27,.39,.43),(.065,.057,.051),(.36,.24,.095),(.075,.065,.14)]
    paths=[(.155,.118,.068),(.18,.28,.33),(.10,.082,.068),(.41,.29,.14),(.12,.092,.18)]
    rgb=np.array(colors[act])[None,None,:]*(1+noise[:,:,None]*4)
    worn=np.zeros((n,n))
    for d in range(6):
        for col in ([1] if d==0 else [0,1,2]):
            for nxt in ([1] if d==5 else [0,1,2]):
                if d not in (0,5) and abs(col-nxt)>1:continue
                ax,ay,_=node_position(d,col);bx,by,_=node_position(d+1,nxt);dx,dy=bx-ax,by-ay
                t=np.clip(((x-ax)*dx+(y-ay)*dy)/(dx*dx+dy*dy),0,1)
                dist=np.hypot(x-ax-t*dx,y-ay-t*dy)
                worn=np.maximum(worn,np.exp(-(dist/.22)**4)*.78)
    rgb=rgb*(1-worn[:,:,None])+np.array(paths[act])[None,None,:]*(1+noise[:,:,None]*3)*worn[:,:,None]
    if act==3:rgb*=1+np.sin(y[:,:,None]*18+x[:,:,None]*2+noise[:,:,None]*20)*.035
    if act==4:
        grid=(np.mod(x*7,1)<.015)|(np.mod(y*7,1)<.015)
        rgb[grid]*=1.4
    rgba=np.ones((n,n,4),dtype=np.float32);rgba[:,:,:3]=np.clip(rgb,.008,.85)
    image=bpy.data.images.new(f'Biome {act} / painted relief',width=n,height=n)
    image.pixels.foreach_set(rgba.ravel());image.pack()
    node=material.node_tree.nodes.new('ShaderNodeTexImage');node.image=image
    bsdf=material.node_tree.nodes.get('Principled BSDF');material.node_tree.links.new(node.outputs['Color'],bsdf.inputs['Base Color'])
    # Fine-grain normals are packed alongside the albedo rather than approximated with faceted geometry.
    gy,gx=np.gradient(noise);normal=np.zeros((n,n,3),dtype=np.float32)
    normal[:,:,0]=-gx*50;normal[:,:,1]=-gy*50;normal[:,:,2]=1
    normal/=np.linalg.norm(normal,axis=2)[:,:,None]
    rgba[:,:,:3]=normal*.5+.5
    im=bpy.data.images.new(f'Biome {act} / soil normal',width=n,height=n)
    im.colorspace_settings.name='Non-Color';im.pixels.foreach_set(rgba.ravel());im.pack()
    tex=material.node_tree.nodes.new('ShaderNodeTexImage');tex.image=im
    bump=material.node_tree.nodes.new('ShaderNodeNormalMap');bump.inputs['Strength'].default_value=.35
    material.node_tree.links.new(tex.outputs['Color'],bump.inputs['Color']);material.node_tree.links.new(bump.outputs['Normal'],bsdf.inputs['Normal'])

GROUND = [(.115,.103,.052),(.27,.37,.41),(.085,.065,.055),(.37,.23,.085),(.095,.09,.16)]
STONE = [(.17,.165,.145),(.25,.34,.39),(.085,.08,.08),(.24,.17,.085),(.13,.12,.22)]
WATER = [(.012,.30,.38),(.025,.36,.52),(1,.105,.002),(.025,.42,.43),(.23,.035,.52)]
worlds = []
for act in range(5):
    rng = random.Random(7019+act*311)
    c = collection(['Verdia / fern valley','Borea / glacial rift','Ignis / broken forge','Aurica / buried relay','Nexus / memory fracture'][act])
    ground = [mat(f'Biome {act} / ground {i}',tuple(v*(.93+i*.025) for v in GROUND[act]),rough=.94,textured=i==3) for i in range(7)]
    stone = [mat(f'Biome {act} / stone {i}',tuple(v*(.72+i*.16) for v in STONE[act]),rough=.87,textured=i==1) for i in range(4)]
    flora = [mat(f'Biome {act} / vegetation {i}',[(.018+i*.006,.049+i*.013,.015+i*.003),(.23+i*.04,.36+i*.055,.40+i*.055),(.06+i*.01,.040+i*.008,.025),(.12+i*.020,.085+i*.014,.025),(.035+i*.014,.025,.065+i*.032)][act],rough=.87) for i in range(4)]
    watermat = mat(f'Biome {act} / animated water',WATER[act],.42,.20,1.5 if act in (2,4) else .15)
    foam = mat(f'Biome {act} / spray',[(.31,.72,.75),(.46,.85,.92),(1,.38,.008),(.15,.65,.60),(.59,.22,.95)][act],.1,.4,.65)
    land = Batch('Terrain / sculpted relief')
    nx, ny = 76, 108
    vs = []
    for j in range(ny+1):
        y=-6.35+j*12.7/ny
        for i in range(nx+1):
            x=-4.65+i*9.3/nx
            h=height(x,y)+rng.uniform(-.018,.018)
            river=-3.65+.28*math.sin(y*.9)
            if abs(x-river)<.43: h-=.16
            vs.append((x,y,h))
    faces=[]
    for j in range(ny):
        for i in range(nx):
            a=j*(nx+1)+i; faces.extend([(a,a+1,a+nx+2),(a,a+nx+2,a+nx+1)])
    land.poly(vs,faces,ground[3])
    paint_terrain(act,ground[3])
    obj=land.object(c)
    for polygon in obj.data.polygons:polygon.use_smooth=True
    uv=obj.data.uv_layers.active
    for polygon in obj.data.polygons:
        for li in polygon.loop_indices:
            co=obj.data.vertices[obj.data.loops[li].vertex_index].co
            uv.data[li].uv=((co.x+4.65)/9.3,(co.y+6.35)/12.7)
    cliffs, plants, ruins, liquid = [Batch(n) for n in ['Cliffs / fractured strata','Flora / scattered miniatures','Ruins / abandoned machinery','Water / falls and currents']]
    for i in range(130):
        x=rng.choice([-1,1])*rng.uniform(3.6,4.5); y=rng.uniform(-6,6)
        if i%3==0: x=-3.0+rng.uniform(-.3,.16)
        if near_route(x,y):continue
        cliffs.rock((x,y,height(x,y)-.04),(rng.uniform(.15,.4),rng.uniform(.16,.36),rng.uniform(.25,.80)),stone[i%4],rng)
    for i in range(470):
        x=rng.uniform(-4.5,4.5); y=rng.uniform(-6.15,6.1)
        river=-3.65+.28*math.sin(y*.9)
        if near_route(x,y) or abs(x-river)<.52:continue
        h=height(x,y); size=rng.uniform(.30,.88)
        if act==0:
            plants.cone((x,y,h+size*.33),.035,size*.7,COPPER,top=.025,n=6)
            for layer in range(4):
                plants.cone((x,y,h+size*(.35+layer*.20)),size*(.36-layer*.065),size*.60,flora[(i+layer)%4],top=0,n=8)
        elif act==1:
            plants.cone((x,y,h+size*.57),size*.16,size*1.1,flora[i%4],top=size*.03,n=5)
            if i%3==0:plants.cone((x+.09,y+.08,h+size*.2),size*.1,size*.6,flora[2],n=5)
        elif act==2:
            plants.rock((x,y,h),(size*.20,size*.17,size*.56),stone[i%4],rng)
            if i%9==0:plants.cone((x,y,h+.06),size*.16,.11,ORANGE,top=size*.12,n=8)
        elif act==3:
            plants.rock((x,y,h),(size*.40,size*.25,size*.20),stone[i%4],rng)
            if i%4==0:
                plants.beam((x,y,h),(x,y,h+size),.045,flora[2],6)
                plants.beam((x,y,h+size*.55),(x+.14,y,h+size*.7),.027,flora[1],6)
        else:
            plants.box((x,y,h+size*.40),(size*.17,size*.14,size*.8),STEEL)
            plants.box((x,y-.075,h+size*.48),(size*.06,.012,size*.45),foam)
    # Tiny ground scatter makes the miniature feel built, without obscuring its route.
    for i in range(600):
        x=rng.uniform(-4.5,4.5);y=rng.uniform(-6.2,6.2)
        if near_route(x,y):continue
        if i%3:continue
        cliffs.rock((x,y,height(x,y)),(.018+rng.random()*.036,.015+rng.random()*.027,.008+rng.random()*.022),ground[3],rng)
    # Western cascades are stepped; separate water geometry can animate at runtime.
    for i in range(110):
        y=-6.3+i*12.6/110; yy=y+12.6/110
        x=-3.65+.28*math.sin(y*.9);xx=-3.65+.28*math.sin(yy*.9)
        z=height(x,y)-.11;zz=height(xx,yy)-.11
        liquid.poly([(x-.32,y,z),(x+.32,y,z),(xx+.32,yy,zz),(xx-.32,yy,zz)],[(0,1,2,3)],watermat)
        for j in range(2):
            sx=x+rng.uniform(-.25,.25); sy=y+rng.uniform(0,.10)
            liquid.box((sx,sy,z+.009),(.01,.045+rng.random()*.11,.008),foam)
        if abs(zz-z)>.20:
            for j in range(12):
                sx=x-.28+j*.047
                liquid.beam((sx,yy,max(z,zz)),(sx,yy,min(z,zz)),.014,foam,5)
    # Broken bridge over the river, collapsed habitat, old relay, and freight remains.
    for y in [-2.55,2.8]:
        z=height(-3.65,y)+.06
        for j in range(8):
            x=-4.45+j*.18
            if j in [3,4]:continue
            ruins.box((x,y,z),(.16,.36,.065),COPPER)
        for side in [-1,1]:
            ruins.beam((-4.45,y+side*.19,z+.18),(-3.17,y+side*.19,z+.18),.025,STEEL)
    for x,y in [(3.6,-3.45),(3.8,3.1),(-2.65,5.8)]:
        z=height(x,y)
        ruins.box((x,y,z+.20),(.75,.6,.4),STEEL,.22)
        for dx in [-.28,.28]: ruins.box((x+dx,y-.305,z+.23),(.06,.02,.33),COPPER)
        ruins.box((x,y-.31,z+.30),(.36,.015,.045),CYAN)
        for j in range(5):ruins.box((x-.25+j*.12,y-.32,z+.12),(.045,.014,.12),EDGE)
    # Ruined circular hull with partial ribs, lodged in the landscape.
    x,y=3.55,-.7;z=height(x,y)
    for i in range(9):
        t=i*math.pi/8
        a=(x+.65*math.cos(t),y-.65,z+.60*math.sin(t));b=(x+.65*math.cos(t),y+.65,z+.60*math.sin(t))
        ruins.beam(a,b,.05,COPPER)
        if i%2==0:ruins.box((a[0],y,a[2]),(.16,1.15,.04),STEEL,.10)
    for batch in (cliffs,plants,ruins,liquid):
        obj=batch.object(c)
        if batch==plants and act==0:
            for polygon in obj.data.polygons:polygon.use_smooth=True
    export('world_%d'%act,c); worlds.append(c)

# Physical command desk: bevelled girders, phosphor screens, vents, cables and lamps.
c=collection('Command desk / original industrial furniture');desk=Batch('Command desk / chassis and instruments')
desk.box((0,0,-.28),(11.2,16.5,.62),STEEL)
desk.box((0,0,.06),(9.55,14.4,.12),DARK)
for x in [-5.08,5.08]:
    desk.box((x,0,.22),(.57,16,.43),STEEL)
    for dx in [-.24,.24]:desk.box((x+dx,0,.47),(.055,16,.05),COPPER)
    for j in range(26):
        y=-7.6+j*.60
        desk.cone((x,y,.48),.074,.04,EDGE,top=.074,n=6)
        if j%3==0:desk.box((x,y+.22,.48),(.22,.13,.035),ORANGE)
    for j in range(9):
        y=-6+j*1.4
        for k in range(4):desk.box((x,y+k*.1,.48),(.28,.038,.02),DARK)
for y in [-7.45,7.45]:
    desk.box((0,y,.20),(10.3,.52,.39),STEEL)
    for dy in [-.23,.23]:desk.box((0,y+dy,.42),(10.3,.05,.04),COPPER)
    for x in range(-4,5):desk.cone((x,y,.43),.07,.035,EDGE,top=.07,n=6)
for x,y in [(-4.82,-5.1),(4.83,4.5),(-4.9,3.6),(4.9,-5.5)]:
    desk.cone((x,y,.63),.18,.37,STEEL,top=.18,n=16)
    desk.cone((x,y,.98),.13,.35,ORANGE,top=.13,n=16)
    for t in range(6):
        angle=t*math.tau/6
        desk.beam((x+.16*math.cos(angle),y+.16*math.sin(angle),.79),(x+.16*math.cos(angle),y+.16*math.sin(angle),1.22),.017,COPPER)
    desk.cone((x,y,1.24),.20,.045,EDGE,top=.20,n=16)
for side in [-1,1]:
    for j in range(3):
        y=4+j*.64
        desk.box((side*4.2,y,.6),(.62,.51,.68),STEEL)
        for k in range(3):desk.box((side*4.2-.2+k*.2,y-.26,.69),(.07,.025,.35),COPPER)
        desk.box((side*4.2,y-.275,.84),(.08,.025,.10),CYAN)
    for j in range(3):
        pts=[(side*4.88,-6.4+j*.2,.50),(side*4.65,-6+j*.2,.54),(side*4.65,-4.9,.51)]
        for a,b in zip(pts,pts[1:]):desk.beam(a,b,.026,COPPER)
# Angled auxiliary monitor, kept clear of touchable route tokens.
desk.box((-4.6,1.7,.85),(.56,.72,.13),COPPER)
desk.box((-4.6,1.7,.93),(.48,.64,.035),DARK)
for j in range(5):desk.box((-4.73,1.46+j*.08,.96),(.12,.013,.014),CYAN)
desk.torus((-4.51,1.76,.961),.13,.008,CYAN,n=32,sides=4)
desk.object(c);export('command_desk',c)

# Route tokens are carved physical objects. Glyphs are added as world-space decals by Godot.
c=collection('Route / titanium token');b=Batch('Route token / bevel and bolts')
b.cone((0,0,.01),.51,.10,STEEL,top=.49,n=48)
b.cone((0,0,.07),.455,.045,DARK,top=.455,n=48)
b.torus((0,0,.092),.46,.014,EDGE,n=48)
for i in range(8):
    t=i*math.tau/8;b.cone((.48*math.cos(t),.48*math.sin(t),.067),.022,.018,COPPER,top=.022,n=6)
b.object(c);export('route_token',c)

c=collection('Route / archon gate');b=Batch('Archon gate / reactor crown')
b.cone((0,0,.04),.79,.12,STEEL,top=.74,n=48)
b.torus((0,0,.12),.69,.036,ORANGE,n=48)
b.torus((0,0,.23),.47,.018,RED,n=40)
for i in range(10):
    t=i*math.tau/10;x=.70*math.cos(t);y=.70*math.sin(t);h=.38+(i%3)*.12
    b.box((x,y,.15+h/2),(.13,.15,h),COPPER,t)
    b.box((x,y,.23+h),(.09,.10,.14),STEEL,t)
    b.beam((x,y,.14),(x*.92,y*.92,.20+h),.015,ORANGE)
b.cone((0,0,.48),.26,.40,STEEL,top=.21,n=12)
b.box((0,-.225,.47),(.39,.065,.22),DARK)
b.box((-.105,-.264,.51),(.115,.015,.04),RED)
b.box((.105,-.264,.51),(.115,.015,.04),RED)
for x in [-.16,-.08,0,.08,.16]:b.box((x,-.21,.27),(.04,.05,.12),EDGE)
b.object(c);export('archon_gate',c)

# A larger, readable player miniature, with ceramic plates, sockets and a lit visor.
c=collection('Player / original exploration robot');b=Batch('Explorer / armour and mechanics')
for x in [-.16,.16]:
    b.box((x,-.045,.11),(.23,.31,.16),STEEL)
    b.box((x,0,.28),(.14,.15,.26),CERAMIC)
    b.cone((x,0,.39),.105,.08,COPPER,top=.105,n=12)
b.box((0,0,.59),(.48,.30,.32),CERAMIC)
b.box((0,-.17,.59),(.28,.035,.21),STEEL)
for x in [-.095,-.055,.055,.095]:b.box((x,-.191,.54),(.019,.015,.06),EDGE)
b.beam((0,-.20,.61),(0,-.235,.61),.065,COPPER,16)
b.beam((0,-.235,.61),(0,-.249,.61),.043,CYAN,16)
b.torus((0,0,.62),.18,.018,CYAN,n=24,sides=5)
b.box((0,0,.82),(.12,.12,.12),COPPER)
b.box((0,0,1.01),(.43,.32,.30),CERAMIC)
b.box((0,-.18,1.02),(.34,.045,.15),DARK)
for x in [-.095,.095]:b.box((x,-.207,1.04),(.10,.023,.035),CYAN)
b.beam((0,0,1.14),(0,0,1.28),.018,EDGE)
b.cone((0,0,1.30),.033,.05,CYAN,top=.025,n=12)
for side in [-1,1]:
    b.box((side*.31,0,.67),(.15,.22,.18),CERAMIC)
    b.beam((side*.31,0,.63),(side*.37,-.04,.43),.07,STEEL)
    b.box((side*.38,-.05,.42),(.13,.19,.12),CERAMIC)
    b.beam((side*.30,-.105,.67),(side*.30,-.14,.67),.055,COPPER,16)
    b.beam((side*.18,.04,.21),(side*.18,.04,.35),.020,EDGE)
    b.box((side*.16,-.11,.15),(.16,.12,.065),CERAMIC)
for obj in [b.object(c)]:
    bevel=obj.modifiers.new('Ceramic bevels','BEVEL');bevel.width=.045;bevel.segments=4
    bpy.context.view_layer.objects.active=obj;obj.select_set(True);bpy.ops.object.modifier_apply(modifier=bevel.name)
mesh=obj
bpy.ops.object.select_all(action='DESELECT')
bpy.ops.object.armature_add(enter_editmode=True)
rig=bpy.context.object;rig.name='Explorer / articulated rig'
for old in list(rig.users_collection):old.objects.unlink(rig)
c.objects.link(rig)
root=rig.data.edit_bones[0];root.name='Root';root.head=(0,0,0);root.tail=(0,0,.12)
specs={'Body':((0,0,.44),(0,0,.82),'Root'),'Head':((0,0,.82),(0,0,1.24),'Body'),
       'Arm.L':((-.30,0,.70),(-.38,-.05,.40),'Body'),'Arm.R':((.30,0,.70),(.38,-.05,.40),'Body'),
       'Leg.L':((-.16,0,.42),(-.16,0,.10),'Root'),'Leg.R':((.16,0,.42),(.16,0,.10),'Root')}
for name,(head,tail,parent) in specs.items():
    bone=rig.data.edit_bones.new(name);bone.head=head;bone.tail=tail;bone.parent=rig.data.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
groups={name:mesh.vertex_groups.new(name=name) for name in ['Root']+list(specs)}
for v in mesh.data.vertices:
    x,y,z=v.co
    bone='Head' if z>.80 else ('Arm.L' if x<0 else 'Arm.R') if abs(x)>.26 and z>.30 else ('Leg.L' if x<0 else 'Leg.R') if z<.44 and abs(x)>.08 else 'Body'
    groups[bone].add([v.index],1,'REPLACE')
mod=mesh.modifiers.new('Original mechanical rig','ARMATURE');mod.object=rig;mesh.parent=rig
def neutral():
    for bone in rig.pose.bones:
        bone.rotation_mode='XYZ';bone.rotation_euler=(0,0,0);bone.location=(0,0,0);bone.scale=(1,1,1)
rig.animation_data_create()
for title,length in [('Idle',48),('Walk',24),('Attack',24),('Deploy',24),('Death',32)]:
    action=bpy.data.actions.new('Explorer_'+title);rig.animation_data.action=action
    for frame in range(0,length+1,4):
        neutral();t=frame/length;bones=rig.pose.bones
        if title=='Idle':
            bones['Body'].location.z=math.sin(t*math.tau)*.012;bones['Head'].rotation_euler.y=math.sin(t*math.tau)*.07
        elif title=='Walk':
            for side,sign in [('L',1),('R',-1)]:
                bones['Leg.'+side].rotation_euler.x=math.sin(t*math.tau)*.32*sign
                bones['Arm.'+side].rotation_euler.x=-math.sin(t*math.tau)*.24*sign
            bones['Body'].location.z=abs(math.sin(t*math.tau))*.035
        elif title=='Attack':
            bones['Arm.R'].rotation_euler.x=-math.sin(t*math.pi)*1.05
            bones['Body'].rotation_euler.y=math.sin(t*math.pi)*.16
        elif title=='Deploy':
            bones['Root'].location.z=(1-t)**2*.8
            bones['Arm.L'].rotation_euler.x=(1-t)*.8;bones['Arm.R'].rotation_euler.x=(1-t)*.8
        else:
            bones['Root'].rotation_euler.x=t*1.1;bones['Body'].rotation_euler.x=t*.25
        for bone in bones:
            bone.keyframe_insert('location',frame=frame);bone.keyframe_insert('rotation_euler',frame=frame)
    rig.animation_data.action=None
    track=rig.animation_data.nla_tracks.new();track.name=title
    strip=track.strips.new(title,1,action);strip.extrapolation='NOTHING';strip.blend_type='REPLACE'
neutral();scene.frame_set(0)
export('explorer',c,True)
manifest['explorer']['animations']=['Idle','Walk','Attack','Deploy','Death']

# Reposition collections for an editable library without affecting exported local coordinates.
for i,c in enumerate(worlds):
    for obj in c.objects:obj.location.x += 14*i
for i,c in enumerate([c for c in scene.collection.children if c not in worlds and c.objects]):
    for obj in c.objects:
        if obj.parent is None:obj.location.y += 22+i*6
scene.world.color=(.035,.043,.06)
camdata=bpy.data.cameras.new('Library camera');cam=bpy.data.objects.new('Library camera',camdata);scene.collection.objects.link(cam)
cam.location=(9,-16,17);cam.rotation_euler=(Vector((0,0,0))-cam.location).to_track_quat('-Z','Y').to_euler();camdata.type='ORTHO';camdata.ortho_scale=19;scene.camera=cam
for p,power,color in [((-5,-2,12),1700,(.55,.85,1)),((5,5,10),2300,(1,.52,.20))]:
    lightdata=bpy.data.lights.new('Library softbox','AREA');lightdata.energy=power;lightdata.color=color;lightdata.shape='DISK';lightdata.size=7
    obj=bpy.data.objects.new('Library softbox',lightdata);scene.collection.objects.link(obj);obj.location=p;obj.rotation_euler=(-obj.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'AstraDioramas.blend'))
manifest['route_positions']={f'{d}_{c}':list(node_position(d,c)) for d in range(7) for c in ([1] if d in [0,6] else [0,1,2])}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
print('DIORAMA LIBRARY:',json.dumps(manifest))
