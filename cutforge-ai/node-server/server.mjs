/** CutForge Node runtime — dependency-free local FFmpeg editor and resumable chunk uploads. */
import http from 'node:http';
import {createReadStream, createWriteStream} from 'node:fs';
import * as fs from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import {fileURLToPath} from 'node:url';
import {randomUUID} from 'node:crypto';
import {spawn, spawnSync} from 'node:child_process';
import {pipeline} from 'node:stream/promises';
import {Transform} from 'node:stream';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const HEX = /^[a-f0-9]{32}$/;
const VIDEO = new Set(['.mp4','.mov','.mkv','.webm','.m4v']);
const AUDIO = new Set(['.mp3','.wav','.ogg','.m4a','.aac']);
const STYLES = {none:'null',vivid:'eq=contrast=1.08:saturation=1.25',warm:'eq=contrast=1.035:saturation=1.12:gamma_r=1.06:gamma_b=0.94',mono:'hue=s=0',cinematic:'eq=contrast=1.15:saturation=0.83'};
const CHUNK_SIZE = 8 * 1024 * 1024;
const MAX_VIDEO = 25 * 1024**3;
const MAX_EFFECT = 50 * 1024**2;
const MAX_JSON = 1024 * 1024;
const respond = (res, code, data) => {
  const value=JSON.stringify(data);
  res.writeHead(code, {'content-type':'application/json; charset=utf-8','content-length':Buffer.byteLength(value),'cache-control':'no-store','x-content-type-options':'nosniff'});
  res.end(value);
};
class HttpError extends Error { constructor(code,message){super(message); this.code=code;} }
function safeId(value){if(!HEX.test(value||'')) throw new HttpError(404,'Not found');return value;}
function executable(name, optionalPath){
  if(optionalPath) return optionalPath;
  const candidate=spawnSync(name,['-version'],{timeout:4000,stdio:'ignore',windowsHide:true});
  return !candidate.error && candidate.status===0 ? name : null;
}
function ffBinary(name) {
  const env = process.env[name==='ffmpeg' ? 'CUTFORGE_FFMPEG' : 'CUTFORGE_FFPROBE'];
  return executable(name,env);
}
const errorMessage = e => e instanceof HttpError ? e.message : 'Internal server error';

function run(binary,args,{timeout=0,logLimit=2*1024*1024}={}){
  return new Promise((resolve,reject)=>{
    if(!binary)return reject(new HttpError(503,'Install FFmpeg (including ffprobe) first.'));
    const proc=spawn(binary,args,{windowsHide:true,stdio:['ignore','pipe','pipe']});
    let output='',error='',settled=false;
    const timer=timeout?setTimeout(()=>{proc.kill('SIGKILL')},timeout):null;
    proc.stdout.on('data',d=>{output=(output+d.toString()).slice(-logLimit)});
    proc.stderr.on('data',d=>{error=(error+d.toString()).slice(-logLimit)});
    proc.on('error',err=>{if(timer)clearTimeout(timer);if(!settled){settled=true;reject(err)}});
    proc.on('close',code=>{if(timer)clearTimeout(timer);if(settled)return;settled=true;resolve({code,output,error})});
  });
}
async function probe(file,ffprobe){
  const r=await run(ffprobe,['-v','error','-show_entries','format=duration:stream=codec_type','-of','json',file],{timeout:45000});
  let parsed;
  try{parsed=JSON.parse(r.output)}catch{throw new HttpError(422,'Unreadable media file')}
  const duration=Number(parsed?.format?.duration);
  if(r.code!==0||!Number.isFinite(duration)||duration<=0||!parsed.streams?.some(s=>s.codec_type==='video'))throw new HttpError(422,'Video has no valid video stream');
  return {duration,has_audio:parsed.streams.some(s=>s.codec_type==='audio')};
}
async function readJson(req){
  let bytes=0,text='';
  for await (const chunk of req){bytes+=chunk.length;if(bytes>MAX_JSON)throw new HttpError(413,'JSON request too large');text+=chunk.toString('utf8')}
  try{return JSON.parse(text)}catch{throw new HttpError(400,'Invalid JSON')}
}
async function jsonFrom(file){try{return JSON.parse(await fs.readFile(file,'utf8'))}catch(e){if(e.code==='ENOENT')throw new HttpError(404,'Not found');throw e}}
async function saveJson(file,value){const tmp=file+'.'+randomUUID()+'.tmp';await fs.writeFile(tmp,JSON.stringify(value,null,2),'utf8');await fs.rename(tmp,file)}
function validateEdits(e,duration,FX){
  if(!e||!Array.isArray(e.segments)||e.segments.length<1||e.segments.length>120)throw new HttpError(422,'Expected 1–120 video segments');
  if(!Object.hasOwn(STYLES,e.style))throw new HttpError(422,'Unknown color preset');
  if(!Array.isArray(e.effects)||e.effects.length>40)throw new HttpError(422,'Maximum 40 sound effects');
  let prev=0,total=0;
  for(const s of e.segments){if(typeof s.start!=='number'||typeof s.end!=='number'||!Number.isFinite(s.start)||!Number.isFinite(s.end)||s.start<0||s.end<=s.start+.045||s.end>duration+.055||s.start+.002<prev)throw new HttpError(422,'Invalid/overlapping segment');prev=s.end;total+=s.end-s.start;}
  for(const fx of e.effects){if(!HEX.test(fx.id||'')||!FX.has(fx.id)||typeof fx.at!=='number'||!Number.isFinite(fx.at)||fx.at<0||fx.at>total||typeof fx.volume!=='number'||!Number.isFinite(fx.volume)||fx.volume<0||fx.volume>2)throw new HttpError(422,'Invalid sound effect');}
  return total;
}
function parseSilence(log,duration,minPause){const items=[];let start=null;for(const line of log.split('\n')){let m=line.match(/silence_start:\s*([\d.]+)/);if(m)start=Number(m[1]);m=line.match(/silence_end:\s*([\d.]+)/);if(m&&start!==null){const end=Math.min(duration,Number(m[1]));if(end-start>=minPause)items.push({start:+start.toFixed(3),end:+end.toFixed(3)});start=null;}}if(start!==null&&duration-start>=minPause)items.push({start:+start.toFixed(3),end:duration});return items;}
function previewMime(ext){return {'.mp4':'video/mp4','.mov':'video/quicktime','.mkv':'video/x-matroska','.webm':'video/webm','.m4v':'video/mp4','.wav':'audio/wav','.mp3':'audio/mpeg','.ogg':'audio/ogg','.aac':'audio/aac','.m4a':'audio/mp4'}[ext]||'application/octet-stream'}
async function sendFile(req,res,filepath,filename){
  const stat=await fs.stat(filepath);
  const ext=path.extname(filepath).toLowerCase();
  const headers={'content-type':previewMime(ext),'accept-ranges':'bytes','x-content-type-options':'nosniff','cache-control':'private, no-store'};
  if(filename)headers['content-disposition']=`attachment; filename="${filename}"`;
  let start=0,end=stat.size-1,status=200;
  const m=/^bytes=(\d*)-(\d*)$/.exec(req.headers.range||'');
  if(req.headers.range){if(!m||(!m[1]&&!m[2])){res.writeHead(416,{'content-range':`bytes */${stat.size}`});res.end();return;}
    if(!m[1]){const suffix=Number(m[2]);start=Math.max(0,stat.size-suffix)}else start=Number(m[1]);
    if(m[1]&&m[2])end=Math.min(end,Number(m[2]));
    if(start>=stat.size||end<start){res.writeHead(416,{'content-range':`bytes */${stat.size}`});res.end();return;}
    status=206;headers['content-range']=`bytes ${start}-${end}/${stat.size}`;
  }
  headers['content-length']=end-start+1;res.writeHead(status,headers);
  await pipeline(createReadStream(filepath,{start,end}),res).catch(()=>{});
}

export function createApp({root=ROOT,data=process.env.CUTFORGE_DATA||path.join(ROOT,'data'),ffmpeg=ffBinary('ffmpeg'),ffprobe=ffBinary('ffprobe')}={}){
  const folders={projects:path.join(data,'projects'),effects:path.join(data,'effects'),uploads:path.join(data,'uploads')};
  const jobs=new Map();
  const ready=Promise.all(Object.values(folders).map(f=>fs.mkdir(f,{recursive:true})));
  const projectDir=id=>path.join(folders.projects,safeId(id));
  const projectFile=id=>path.join(projectDir(id),'project.json');
  const load=id=>jsonFrom(projectFile(id));
  const effectFile=async id=>{safeId(id);for(const ext of AUDIO){const file=path.join(folders.effects,id+ext);try{await fs.access(file);return file}catch{}}throw new HttpError(422,'Unknown sound effect')};
  async function allEffects(){const files=await fs.readdir(folders.effects);const results=[];for(const file of files){if(!AUDIO.has(path.extname(file))||!HEX.test(path.parse(file).name))continue;const id=path.parse(file).name;let label=file;try{label=(await jsonFrom(path.join(folders.effects,id+'.json'))).name}catch{}results.push({id,name:label});}return results.sort((a,b)=>a.name.localeCompare(b.name));}
  async function completedUpload(u){
    const src=path.join(folders.uploads,u.id+'.bin');
    if(u.received!==u.size)throw new HttpError(409,'Upload not yet complete');
    const ext=path.extname(u.name).toLowerCase();
    const allowed=u.kind==='video'?VIDEO:AUDIO;
    if(!allowed.has(ext))throw new HttpError(415,'Unsupported media format');
    if(u.kind==='video'){
      const metadata=await probe(src,ffprobe);
      const pid=randomUUID().replace(/-/g,'');const dir=projectDir(pid);await fs.mkdir(dir);
      try{
        await fs.rename(src,path.join(dir,'source'+ext));
        const project={id:pid,name:u.name,source:'source'+ext,...metadata,segments:[{start:0,end:metadata.duration}],style:'none',effects:[],suggestions:[]};
        await saveJson(path.join(dir,'project.json'),project);
        await fs.rm(path.join(folders.uploads,u.id+'.json'),{force:true});
        return project;
      }catch(e){await fs.rm(dir,{recursive:true,force:true});throw e}
    }
    const result=await run(ffprobe,['-v','error','-select_streams','a:0','-show_entries','stream=codec_type','-of','csv=p=0',src],{timeout:30000});
    if(result.code!==0||!result.output.includes('audio'))throw new HttpError(422,'Invalid sound file');
    const id=randomUUID().replace(/-/g,'');await fs.rename(src,path.join(folders.effects,id+ext));await saveJson(path.join(folders.effects,id+'.json'),{name:u.name});await fs.rm(path.join(folders.uploads,u.id+'.json'),{force:true});return {id,name:u.name};
  }
  async function renderJob(jobId,project,edits,length){
    const job=jobs.get(jobId);const dir=projectDir(project.id),output=path.join(dir,`export-${jobId}.mp4`),script=path.join(dir,`render-${jobId}.filter`);
    try{
      const fxFiles=await Promise.all(edits.effects.map(x=>effectFile(x.id)));
      const filters=[];
      edits.segments.forEach((s,i)=>{filters.push(`[0:v]trim=start=${s.start.toFixed(6)}:end=${s.end.toFixed(6)},setpts=PTS-STARTPTS,${STYLES[edits.style]}[v${i}]`);
        filters.push(project.has_audio?`[0:a]atrim=start=${s.start.toFixed(6)}:end=${s.end.toFixed(6)},asetpts=PTS-STARTPTS[a${i}]`:`anullsrc=r=48000:cl=stereo,atrim=duration=${(s.end-s.start).toFixed(6)},asetpts=PTS-STARTPTS[a${i}]`);
      });
      filters.push(edits.segments.map((_,i)=>`[v${i}][a${i}]`).join('')+`concat=n=${edits.segments.length}:v=1:a=1[vout][abase]`);
      edits.effects.forEach((e,i)=>{const delay=Math.round(e.at*1000);filters.push(`[${i+1}:a]aformat=sample_rates=48000:channel_layouts=stereo,volume=${e.volume.toFixed(3)},adelay=${delay}|${delay}[fx${i+1}]`)});
      if(edits.effects.length)filters.push('[abase]'+edits.effects.map((_,i)=>`[fx${i+1}]`).join('')+`amix=inputs=${edits.effects.length+1}:duration=first:dropout_transition=0:normalize=0[aout]`);
      else filters.push('[abase]anull[aout]');
      await fs.writeFile(script,filters.join(';\n'));
      const args=['-hide_banner','-nostdin','-loglevel','error','-y','-progress','pipe:1','-i',path.join(dir,project.source),...fxFiles.flatMap(f=>['-i',f]),'-filter_complex_script',script,'-map','[vout]','-map','[aout]','-c:v','libx264','-preset','veryfast','-crf','23','-pix_fmt','yuv420p','-c:a','aac','-b:a','192k','-movflags','+faststart',output];
      const proc=spawn(ffmpeg,args,{windowsHide:true,stdio:['ignore','pipe','pipe']});
      let stderr='',stdout='';
      proc.stdout.on('data',d=>{stdout+=d.toString();let n=stdout.indexOf('\n');while(n!==-1){const line=stdout.slice(0,n);stdout=stdout.slice(n+1);const value=line.match(/^out_time_(?:ms|us)=(\d+)/);if(value){job.progress=Math.min(99,Math.round(Number(value[1])/1e6/length*100));}n=stdout.indexOf('\n')}});
      proc.stderr.on('data',d=>{stderr=(stderr+d.toString()).slice(-2500)});
      const code=await new Promise((resolve,reject)=>{proc.on('error',reject);proc.on('close',resolve)});
      if(code!==0)throw Error('FFmpeg render failed: '+stderr.slice(-1000));
      await fs.access(output);job.state='done';job.progress=100;
    }catch(err){job.state='error';job.error=String(err.message||err).slice(0,700);await fs.rm(output,{force:true});}
    finally{await fs.rm(script,{force:true})}
  }
  const server=http.createServer(async(req,res)=>{
    try{
      await ready;
      const host=(req.headers.host||'').toLowerCase();
      const publicHost=(process.env.CUTFORGE_PUBLIC_HOST||'').toLowerCase();
      const hostname=host.replace(/:\d+$/,'');
      if(!['localhost','127.0.0.1','[::1]'].includes(hostname) && hostname!==publicHost && !(process.env.CUTFORGE_ALLOW_QUICK_TUNNEL==='1' && /^[a-z0-9-]+\.trycloudflare\.com$/.test(hostname)))throw new HttpError(403,'Remote hostname not authorized');
      if(!['GET','HEAD','OPTIONS'].includes(req.method) && req.headers.origin){
        try {if(new URL(req.headers.origin).host.toLowerCase()!==host)throw new Error('Bad origin')}catch{throw new HttpError(403,'Cross-origin requests blocked')}
      }
      const url=new URL(req.url,'http://localhost');const route=url.pathname;const method=req.method;
      if(method==='GET'&&route==='/api/health')return respond(res,200,{ok:true,engine:'node',ffmpeg:!!ffmpeg,ffprobe:!!ffprobe});
      if(method==='GET'&&route==='/api/projects'){
        const dirs=await fs.readdir(folders.projects);const result=[];for(const dir of dirs){if(!HEX.test(dir))continue;try{const p=await load(dir);result.push({id:p.id,name:p.name,duration:p.duration})}catch{}}return respond(res,200,result.sort((a,b)=>a.name.localeCompare(b.name)));
      }
      if(method==='POST'&&route==='/api/uploads'){
        const u=await readJson(req);const name=path.basename(String(u.name||'')).slice(0,240);const kind=u.kind;
        const size=Number(u.size);const allowed=kind==='video'?VIDEO:kind==='effect'?AUDIO:null;
        if(!allowed||!allowed.has(path.extname(name).toLowerCase()))throw new HttpError(415,'Unsupported file extension');
        if(!Number.isSafeInteger(size)||size<=0||size>(kind==='video'?MAX_VIDEO:MAX_EFFECT))throw new HttpError(413,'Invalid or oversized file');
        const id=randomUUID().replace(/-/g,'');const record={id,name,kind,size,received:0,next:0};await fs.writeFile(path.join(folders.uploads,id+'.bin'),'');await saveJson(path.join(folders.uploads,id+'.json'),record);
        return respond(res,200,{id,chunk_size:CHUNK_SIZE});
      }
      let m=route.match(/^\/api\/uploads\/([a-f0-9]{32})\/chunks\/(\d+)$/);
      if(m&&method==='PUT'){
        const id=safeId(m[1]),index=Number(m[2]),file=path.join(folders.uploads,id+'.bin');const meta=path.join(folders.uploads,id+'.json');const u=await jsonFrom(meta);
        const expected=Math.min(CHUNK_SIZE,u.size-u.received);
        if(index!==u.next||expected<=0)throw new HttpError(409,'Wrong chunk index');
        if(Number(req.headers['content-length'])!==expected)throw new HttpError(422,'Wrong chunk size');
        let bytes=0;const limit=new Transform({transform(chunk,encoding,callback){bytes+=chunk.length;if(bytes>expected)callback(new HttpError(413,'Chunk too large'));else callback(null,chunk)}});
        try{await pipeline(req,limit,createWriteStream(file,{flags:'a'}));if(bytes!==expected)throw new HttpError(422,'Incomplete chunk');}
        catch(err){await fs.truncate(file,u.received);throw err}
        u.received+=bytes;u.next++;await saveJson(meta,u);return respond(res,200,{received:u.received,next:u.next});
      }
      m=route.match(/^\/api\/uploads\/([a-f0-9]{32})\/complete$/);
      if(m&&method==='POST'){const u=await jsonFrom(path.join(folders.uploads,safeId(m[1])+'.json'));return respond(res,200,await completedUpload(u));}
      m=route.match(/^\/api\/projects\/([a-f0-9]{32})$/);
      if(m&&method==='GET')return respond(res,200,await load(m[1]));
      m=route.match(/^\/api\/projects\/([a-f0-9]{32})\/media$/);
      if(m&&method==='GET'){const p=await load(m[1]);return await sendFile(req,res,path.join(projectDir(p.id),p.source));}
      m=route.match(/^\/api\/projects\/([a-f0-9]{32})\/analyze$/);
      if(m&&method==='POST'){
        const p=await load(m[1]);const threshold=Number(url.searchParams.get('threshold')??-36),minPause=Number(url.searchParams.get('min_pause')??.6);
        if(threshold< -65||threshold> -15||minPause<.2||minPause>10||!Number.isFinite(threshold)||!Number.isFinite(minPause))throw new HttpError(422,'Invalid detection settings');
        if(!p.has_audio)return respond(res,200,{suggestions:[],note:'Video has no audio track'});
        const r=await run(ffmpeg,['-hide_banner','-nostdin','-i',path.join(projectDir(p.id),p.source),'-vn','-af',`silencedetect=noise=${threshold}dB:d=${minPause}`,'-f','null','-'],{timeout:15*60*1000});
        if(r.code!==0)throw new HttpError(500,'Silence detection failed');p.suggestions=parseSilence(r.error,p.duration,minPause);await saveJson(projectFile(p.id),p);
        return respond(res,200,{suggestions:p.suggestions,note:`Found ${p.suggestions.length} silence regions`});
      }
      m=route.match(/^\/api\/projects\/([a-f0-9]{32})\/edit$/);
      if(m&&method==='PUT'){
        const p=await load(m[1]);const edit=await readJson(req);const fx=new Set((await allEffects()).map(e=>e.id));validateEdits(edit,p.duration,fx);
        p.segments=edit.segments;p.style=edit.style;p.effects=edit.effects;await saveJson(projectFile(p.id),p);return respond(res,200,p);
      }
      m=route.match(/^\/api\/projects\/([a-f0-9]{32})\/render$/);
      if(m&&method==='POST'){
        const p=await load(m[1]);const edit=await readJson(req);const fx=new Set((await allEffects()).map(e=>e.id));const length=validateEdits(edit,p.duration,fx);
        if([...jobs.values()].some(j=>j.project_id===p.id&&j.state==='working'))throw new HttpError(409,'Render already running');
        p.segments=edit.segments;p.style=edit.style;p.effects=edit.effects;await saveJson(projectFile(p.id),p);
        const id=randomUUID().replace(/-/g,'');const job={id,project_id:p.id,state:'working',progress:0,error:null};jobs.set(id,job);void renderJob(id,p,edit,length);return respond(res,200,job);
      }
      if(method==='GET'&&route==='/api/effects')return respond(res,200,await allEffects());
      m=route.match(/^\/api\/effects\/([a-f0-9]{32})\/media$/);
      if(m&&method==='GET')return await sendFile(req,res,await effectFile(m[1]));
      m=route.match(/^\/api\/jobs\/([a-f0-9]{32})$/);
      if(m&&method==='GET'){const job=jobs.get(m[1]);if(!job)throw new HttpError(404,'Render job not found');return respond(res,200,job)}
      m=route.match(/^\/api\/jobs\/([a-f0-9]{32})\/download$/);
      if(m&&method==='GET'){const job=jobs.get(m[1]);if(!job||job.state!=='done')throw new HttpError(404,'Export not ready');return await sendFile(req,res,path.join(projectDir(job.project_id),`export-${job.id}.mp4`),'cutforge-export.mp4')}
      if(route.startsWith('/api/'))throw new HttpError(404,'API route not found');
      // Only explicitly allow static files. Never expose local data, .env or backend files.
      const statics={'/':'index.html','/index.html':'index.html','/app.js':'app.js','/app.css':'app.css'};
      if(method==='GET'&&Object.hasOwn(statics,route)){
        const file=path.join(root,'frontend',statics[route]);const buf=await fs.readFile(file);
        const type=route.endsWith('.js')?'text/javascript':route.endsWith('.css')?'text/css':'text/html';
        res.writeHead(200,{'content-type':type+'; charset=utf-8','content-length':buf.length,'x-content-type-options':'nosniff','cache-control':'no-cache'});res.end(buf);return;
      }
      throw new HttpError(404,'Not found');
    }catch(err){if(!res.headersSent){if(!(err instanceof HttpError))console.error('CutForge error:',err);respond(res,err.code||500,{detail:errorMessage(err)})}else res.destroy(err)}
  });
  return {server,ready,jobs,folders};
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  const app=createApp();const port=Number(process.env.CUTFORGE_PORT||8000);
  const host=process.env.CUTFORGE_HOST||'127.0.0.1';
  app.server.listen(port,host,()=>console.log(`CutForge AI (Node) ready at http://${host}:${port}`));
}