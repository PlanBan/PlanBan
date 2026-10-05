"""Render the original explorer portrait from the editable Blender library.
Run after generate_dioramas.py; factory-startup is recommended.
"""
from pathlib import Path
import bpy
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(ROOT.parent/'OrbitGuardians-Blender/AstraDioramas.blend'))
scene=bpy.context.scene
explorer=bpy.data.collections['Player / original exploration robot']
for obj in scene.objects:
    obj.hide_render=obj not in list(explorer.objects) and obj.type not in ('LIGHT','CAMERA')
points=[obj.matrix_world@Vector(corner) for obj in explorer.objects if obj.type=='MESH' for corner in obj.bound_box]
center=Vector([(min(p[i] for p in points)+max(p[i] for p in points))/2 for i in range(3)])
scene.camera.location=center+Vector((1.45,-2.8,1.2))
scene.camera.rotation_euler=(center-scene.camera.location).to_track_quat('-Z','Y').to_euler()
scene.camera.data.ortho_scale=1.65
for i,obj in enumerate([o for o in scene.objects if o.type=='LIGHT']):
    obj.location=center+Vector((-3,-4,5) if i==0 else (3,2,4))
    obj.rotation_euler=(center-obj.location).to_track_quat('-Z','Y').to_euler()
    obj.data.energy=400 if i==0 else 600;obj.data.size=4
scene.render.resolution_x=scene.render.resolution_y=512
scene.render.resolution_percentage=100;scene.render.film_transparent=True
scene.render.filepath=str(ROOT/'assets3d/tabletop/portraits/pulse.png')
scene.cycles.samples=64;scene.cycles.use_denoising=False
bpy.ops.render.render(write_still=True)
