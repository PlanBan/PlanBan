import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import path from 'node:path';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const candidates = process.env.CUTFORGE_PYTHON
  ? [[process.env.CUTFORGE_PYTHON]]
  : process.platform === 'win32' ? [['py', '-3'], ['python'], ['python3']] : [['python3'], ['python']];
export function detectPython() {
  for (const candidate of candidates) {
    const cmd = spawnSync(candidate[0], [...candidate.slice(1), '-c',
      'import sys; assert sys.version_info >= (3,10); print(sys.version.split()[0])'],
    {encoding:'utf8',timeout:5000,windowsHide:true});
    if (cmd.status === 0) return {binary:candidate[0], prefix:candidate.slice(1),version:cmd.stdout.trim()};
  }
  return null;
}
export function assertPython() {
  const py=detectPython();
  if (!py) throw Error('Python 3.10+ не найден. Установи Python и отметь Add to PATH. Проверь: py -3 --version');
  return py;
}
if (process.argv[1] && path.resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
  try {
    const py=assertPython();
    console.log(`✓ Python ${py.version}: ${py.binary} ${py.prefix.join(' ')}`);
    const script = process.argv.includes('--test') ? 'test_silence.py' : 'silence.py';
    const result=spawnSync(py.binary,[...py.prefix, path.join(root,'python-workers',script), ...(script==='silence.py' ? ['--self-test'] : [])],
      {encoding:'utf8',timeout:15000,windowsHide:true,cwd:root});
    if(result.status!==0) throw Error((result.stderr||result.stdout||`Python returned ${result.status}`).slice(0,2500));
    if(result.stdout.trim()) console.log(result.stdout.trim());
  }catch(err){console.error(`✗ ${err.message}`);process.exitCode=1;}
}
