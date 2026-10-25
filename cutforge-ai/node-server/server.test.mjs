import {test} from 'node:test';
import assert from 'node:assert/strict';
import os from 'node:os';
import path from 'node:path';
import {mkdtemp,readFile,rm,writeFile} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import {createApp} from './server.mjs';

async function withApp(fn){
  const data=await mkdtemp(path.join(os.tmpdir(),'cutforge-node-'));
  const app=createApp({data});await app.ready;
  await new Promise(resolve=>app.server.listen(0,'127.0.0.1',resolve));
  const origin=`http://127.0.0.1:${app.server.address().port}`;
  async function req(endpoint,options={}){const r=await fetch(origin+endpoint,options);let body;const content=r.headers.get('content-type')||'';if(content.includes('application/json')) body=await r.json();else body=Buffer.from(await r.arrayBuffer());return {status:r.status,body,headers:r.headers};}
  try{await fn({req,origin,data})}finally{await new Promise(resolve=>app.server.close(resolve));await rm(data,{force:true,recursive:true})}
}
function demo(file,hasAudio=true){
  const args=['-hide_banner','-v','error','-y','-f','lavfi','-i','color=c=blue:s=160x90:r=15:d=3'];
  if(hasAudio)args.push('-f','lavfi','-i','sine=frequency=550:duration=1','-filter_complex','[1:a]apad=pad_dur=2[a]','-map','0:v','-map','[a]');
  else args.push('-an');
  args.push('-c:v','libx264',...(hasAudio?['-c:a','aac']:[]),'-t','3',file);
  const r=spawnSync('ffmpeg',args);assert.equal(r.status,0,r.stderr?.toString());
}
async function upload(req,kind,name,buf){
  const start=await req('/api/uploads',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({kind,name,size:buf.length})});assert.equal(start.status,200,start.body?.detail);
  const {id,chunk_size}=start.body;
  const chunks=Math.ceil(buf.length/chunk_size);
  for(let i=0;i<chunks;i++){
    const part=buf.subarray(i*chunk_size,(i+1)*chunk_size);
    const result=await req(`/api/uploads/${id}/chunks/${i}`,{method:'PUT',headers:{'content-type':'application/octet-stream'},body:part});assert.equal(result.status,200,result.body?.detail);
  }
  const finish=await req(`/api/uploads/${id}/complete`,{method:'POST',headers:{'content-type':'application/json'},body:'{}'});
  assert.equal(finish.status,200,JSON.stringify(finish.body));return finish.body;
}
async function waitDone(req,id){for(let i=0;i<150;i++){const r=await req('/api/jobs/'+id);if(r.body.state!=='working')return r.body;await new Promise(resolve=>setTimeout(resolve,150));}throw Error('timeout')}

test('Node: upload, pause analysis, edit, range streaming and export',async()=>{
  await withApp(async({req,data})=>{
    const file=path.join(data,'demo.mp4');demo(file);
    const project=await upload(req,'video','demo.mp4',await readFile(file));
    assert.ok(project.duration>2.5);
    assert.equal((await req('/api/health')).body.engine,'node');
    assert.equal((await req('/api/projects')).body.length,1);
    const range=await req(`/api/projects/${project.id}/media`,{headers:{range:'bytes=0-15'}});assert.equal(range.status,206);assert.equal(range.body.length,16);
    const analyze=await req(`/api/projects/${project.id}/analyze?threshold=-28&min_pause=0.4`,{method:'POST'});
    assert.equal(analyze.status,200);assert.ok(analyze.body.suggestions.some(s=>s.start>.6&&s.end>2.8));
    const edits={segments:[{start:0,end:.6},{start:1.4,end:2.6}],style:'warm',effects:[]};
    assert.equal((await req(`/api/projects/${project.id}/edit`,{method:'PUT',headers:{'content-type':'application/json'},body:JSON.stringify(edits)})).status,200);
    const invalid={...edits,segments:[{start:0,end:2},{start:1,end:2.5}]};
    assert.equal((await req(`/api/projects/${project.id}/edit`,{method:'PUT',headers:{'content-type':'application/json'},body:JSON.stringify(invalid)})).status,422);
    const j=await req(`/api/projects/${project.id}/render`,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(edits)});
    assert.equal(j.status,200);const done=await waitDone(req,j.body.id);assert.equal(done.state,'done',done.error);
    const exported=await req(`/api/jobs/${j.body.id}/download`);assert.equal(exported.status,200);assert.ok(exported.body.length>1000);
    assert.equal((await req('/app.js')).status,200);
  });
});

test('Node: sound effects, silent source, invalid media and access restrictions',async()=>{
  await withApp(async({req,data,origin})=>{
    const invalid=await uploadBad();
    async function uploadBad(){const start=await req('/api/uploads',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({kind:'video',name:'bad.mp4',size:4})});
      const id=start.body.id;await req(`/api/uploads/${id}/chunks/0`,{method:'PUT',body:Buffer.from('junk')});return req(`/api/uploads/${id}/complete`,{method:'POST'});}
    assert.equal(invalid.status,422);
    const silent=path.join(data,'silent.mp4');demo(silent,false);const project=await upload(req,'video','silent.mp4',await readFile(silent));
    const sound=path.join(data,'effect.wav');const r=spawnSync('ffmpeg',['-v','error','-y','-f','lavfi','-i','sine=frequency=900:duration=0.2',sound]);assert.equal(r.status,0);
    const effect=await upload(req,'effect','effect.wav',await readFile(sound));
    const edits={segments:[{start:0,end:1.5}],style:'none',effects:[{id:effect.id,at:.5,volume:.65}]};
    const job=await req(`/api/projects/${project.id}/render`,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(edits)});
    assert.equal(job.status,200);
    const done=await waitDone(req,job.body.id);assert.equal(done.state,'done',done.error);
    assert.equal((await req(`/api/jobs/${job.body.id}/download`)).status,200);
    const foreign=await req('/api/projects',{method:'POST',headers:{Origin:'https://evil.example','content-type':'application/json'},body:'{}'});assert.equal(foreign.status,403);
    assert.equal((await req('/.env')).status,404);
  });
});

test('Node + Python: asynchronous pause analysis with persisted results', async()=>{
  await withApp(async({req,data})=>{
    const health=await req('/api/health');
    assert.equal(health.body.python,true,'Python worker must be available');
    const file=path.join(data,'async-demo.mp4');demo(file,true);
    const project=await upload(req,'video','async-demo.mp4',await readFile(file));
    const response=await req(`/api/projects/${project.id}/analyze-async?threshold=-28&min_pause=0.4`,{method:'POST'});
    assert.equal(response.status,200);
    assert.equal(response.body.type,'analysis');
    const done=await waitDone(req,response.body.id);
    assert.equal(done.state,'done',done.error);
    assert.ok(done.result.suggestions.some(s=>s.start>.7 && s.end>2.8));
    const saved=(await req(`/api/projects/${project.id}`)).body;
    assert.deepEqual(saved.suggestions,done.result.suggestions);
  });
});
