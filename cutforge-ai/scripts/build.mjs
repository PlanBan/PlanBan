import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
import {assertPython} from './check-python.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const command=(binary,args)=>{const result=spawnSync(binary,args,{stdio:'inherit',cwd:root,windowsHide:true});if(result.status!==0)throw Error(`${binary} failed with exit code ${result.status}`);};
try{
  if(Number(process.versions.node.split('.')[0])<20)throw Error('Node.js 20+ required');
  command(process.execPath,['--check','node-server/server.mjs']);
  command(process.execPath,['--check','frontend/app.js']);
  command(process.execPath,['--check','scripts/dev.mjs']);
  const py=assertPython();
  command(py.binary,[...py.prefix,'python-workers/silence.py','--self-test']);
  if(!process.argv.includes('--check-only')){
    const dist=path.join(root,'dist');
    await fs.mkdir(dist,{recursive:true});
    for(const file of ['index.html','app.js','app.css'])await fs.copyFile(path.join(root,'frontend',file),path.join(dist,file));
    console.log('✓ Build: validated Node.js, Python; copied frontend assets to dist/');
  }else console.log('✓ Integrity checks: Node.js and Python are OK');
}catch(err){console.error('✗ Build failed:',err.message);process.exitCode=1;}
