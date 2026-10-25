import importlib
import json
import os
import subprocess
import time

import pytest
from fastapi.testclient import TestClient


@pytest.fixture()
def fixture_app(tmp_path, monkeypatch):
    monkeypatch.setenv('CUTFORGE_DATA', str(tmp_path / 'data'))
    import backend.app as backend
    importlib.reload(backend)
    client = TestClient(backend.app)
    video = tmp_path / 'example.mp4'
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'lavfi', '-i',
                    'color=c=purple:s=160x90:r=15:d=3', '-f', 'lavfi', '-i',
                    'sine=frequency=550:duration=1', '-filter_complex',
                    '[1:a]apad=pad_dur=2[a]', '-map', '0:v', '-map', '[a]',
                    '-c:v', 'libx264', '-c:a', 'aac', '-t', '3', str(video)],
                   check=True)
    return client, video


def test_upload_analyze_save_and_export(fixture_app):
    client, video = fixture_app
    health = client.get('/api/health').json()
    assert health['ok'] and health['ffmpeg']
    with video.open('rb') as f:
        response = client.post('/api/projects', files={'file': ('video.mp4', f, 'video/mp4')})
    assert response.status_code == 200, response.text
    project = response.json()
    assert 2.8 < project['duration'] < 3.1
    assert client.get('/api/projects').json()[0]['id'] == project['id']
    assert client.get(f"/api/projects/{project['id']}/media").status_code == 200
    suggestions = client.post(f"/api/projects/{project['id']}/analyze", params={'threshold': -28, 'min_pause': .4}).json()['suggestions']
    assert any(s['start'] > .6 and s['end'] >= 2.9 for s in suggestions), suggestions
    edits = {'segments': [{'start': 0, 'end': .6}, {'start': 1.4, 'end': 2.6}], 'style': 'warm', 'effects': []}
    assert client.put(f"/api/projects/{project['id']}/edit", json=edits).status_code == 200
    bad = {'segments': [{'start': 0, 'end': 2}, {'start': 1, 'end': 2.5}], 'style': 'none', 'effects': []}
    assert client.put(f"/api/projects/{project['id']}/edit", json=bad).status_code == 422
    result = client.post(f"/api/projects/{project['id']}/render", json=edits)
    assert result.status_code == 200, result.text
    jobid = result.json()['id']
    for _ in range(70):
        status=client.get(f'/api/jobs/{jobid}').json()
        if status['state'] != 'working': break
        time.sleep(.2)
    assert status['state']=='done', status
    download=client.get(f'/api/jobs/{jobid}/download')
    assert download.status_code == 200 and len(download.content)>1000
    assert client.get('/').status_code==200


def test_bad_upload_and_path(fixture_app):
    client, _ = fixture_app
    response=client.post('/api/projects', files={'file': ('bad.mp4', b'not video', 'video/mp4')})
    assert response.status_code==422
    response=client.post('/api/projects', files={'file': ('bad.txt', b'text', 'text/plain')})
    assert response.status_code==415
    assert client.get('/api/projects/../etc/media').status_code in (404, 405)


def test_sfx_mix(fixture_app, tmp_path):
    client, video = fixture_app
    with video.open('rb') as f:
        project=client.post('/api/projects', files={'file': ('video.mp4',f,'video/mp4')}).json()
    sfx=tmp_path/'sfx.wav'
    subprocess.run(['ffmpeg','-v','error','-y','-f','lavfi','-i',
                    'sine=frequency=880:duration=0.25','-c:a','pcm_s16le',str(sfx)],check=True)
    with sfx.open('rb') as f:
        effect=client.post('/api/effects',files={'file':('sfx.wav',f,'audio/wav')})
    assert effect.status_code==200,effect.text
    eid=effect.json()['id']
    assert any(e['id']==eid for e in client.get('/api/effects').json())
    edits={'segments':[{'start':0,'end':1.5}],'style':'none','effects':[{'id':eid,'at':.5,'volume':.7}]}
    job=client.post(f"/api/projects/{project['id']}/render",json=edits)
    assert job.status_code==200,job.text
    jid=job.json()['id']
    for _ in range(70):
        status=client.get(f'/api/jobs/{jid}').json()
        if status['state']!='working':break
        time.sleep(.2)
    assert status['state']=='done',status
