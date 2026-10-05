"""Package the already exported game and clean Godot/Blender sources; verify ZIPs."""
from pathlib import Path
import hashlib, zipfile, shutil
ROOT = Path(__file__).resolve().parents[2]
PROJECT = ROOT / 'OrbitGuardians'
BLENDER = ROOT / 'OrbitGuardians-Blender'
with zipfile.ZipFile(ROOT / 'OrbitGuardians-Source.zip', 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
    for folder in (PROJECT, BLENDER):
        for path in sorted(folder.rglob('*')):
            if not path.is_file(): continue
            if any(part in ('.godot', 'build', '__pycache__') for part in path.relative_to(folder).parts): continue
            if path.suffix in ('.tmp', '.blend1') or path.name.startswith('qa_'): continue
            archive.write(path, path.relative_to(ROOT))
with zipfile.ZipFile(ROOT / 'OrbitGuardians-Windows.zip', 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
    executable = PROJECT / 'build' / 'OrbitGuardians.exe'
    assert executable.read_bytes()[:2] == b'MZ', 'Export a Windows executable first'
    archive.write(executable, 'OrbitGuardians/OrbitGuardians.exe')
    archive.write(PROJECT / 'README.md', 'OrbitGuardians/README.md')
    archive.write(PROJECT / 'VALIDATION.md', 'OrbitGuardians/VALIDATION.md')
    archive.write(ROOT / 'OrbitGuardians-preview.png', 'OrbitGuardians/preview.png')
apk = PROJECT / 'build' / 'OrbitalFront-Android.apk'
with zipfile.ZipFile(apk) as archive:
    assert archive.testzip() is None
    assert 'AndroidManifest.xml' in archive.namelist()
shutil.copy2(apk, ROOT / 'OrbitalFront-Android.apk')
checksums=[]
for name in ['OrbitGuardians-Source.zip', 'OrbitGuardians-Windows.zip', 'OrbitalFront-Android.apk']:
    path=ROOT/name
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None
        names=archive.namelist()
        if name.endswith('.zip'): assert not any('/.godot/' in n or '/build/' in n or n.endswith('.blend1') for n in names)
    checksums.append(hashlib.file_digest(path.open('rb'), 'sha256').hexdigest()+'  '+name)
    print('ZIP VERIFIED:',name,path.stat().st_size,'bytes')
(ROOT/'OrbitGuardians-SHA256SUMS.txt').write_text('\n'.join(checksums)+'\n')
