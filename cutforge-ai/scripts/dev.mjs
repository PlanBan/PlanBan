import {createApp} from '../node-server/server.mjs';
import {assertPython} from './check-python.mjs';
import {spawnSync} from 'node:child_process';
try {
  if(Number(process.versions.node.split('.')[0])<20)throw Error('Node.js 20+ required');
  const py=assertPython();
  const ffmpeg=spawnSync(process.env.CUTFORGE_FFMPEG||'ffmpeg',['-version'],{stdio:'ignore',windowsHide:true,timeout:5000});
  const ffprobe=spawnSync(process.env.CUTFORGE_FFPROBE||'ffprobe',['-version'],{stdio:'ignore',windowsHide:true,timeout:5000});
  if(ffmpeg.status!==0||ffprobe.status!==0)throw Error('FFmpeg/FFprobe не найдены. Установи FFmpeg и добавь в PATH, затем открой новый PowerShell.');
  const app=createApp();
  await app.ready;
  const host='127.0.0.1',port=Number(process.env.CUTFORGE_PORT||8000);
  app.server.on('error',err=>{console.error('✗ Сервер не запустился:',err.message,'(занят порт '+port+'?)');process.exitCode=1;});
  app.server.listen(port,host,()=>{
    console.log(`\n🎬 CutForge AI 0.3 · Node.js + Python ${py.version} + FFmpeg`);
    console.log(`Открой в браузере: http://${host}:${port}`);
    console.log('Для остановки нажми Ctrl+C. Исходники и проекты остаются в папке data/.\n');
  });
}catch(err){console.error('✗ Ошибка запуска:',err.message);process.exitCode=1;}
