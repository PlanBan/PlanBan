/* CutForge AI — zero-build local editor. The source file is never modified. */
(() => {
  'use strict';
  const $ = (id) => document.getElementById(id);
  const video = $('video');
  const state = { project: null, mode: 'auto', selected: 0, suggestions: [], checked: [], assets: [], history: [], saving: false, job: null };
  const fmt = (seconds) => {
    const n = Math.max(0, Math.floor(Number(seconds) || 0));
    return `${String(Math.floor(n/3600)).padStart(2,'0')}:${String(Math.floor(n%3600/60)).padStart(2,'0')}:${String(n%60).padStart(2,'0')}`.replace(/^00:/,'');
  };
  const outputLength = () => (state.project?.segments || []).reduce((sum,s) => sum+s.end-s.start,0);
  const clamp = (n,low,high) => Math.max(low,Math.min(high,n));
  const esc = (str) => String(str).replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
  let toastTimer;
  function notify(message){ $('toast').textContent=message; $('toast').classList.add('visible'); clearTimeout(toastTimer);toastTimer=setTimeout(()=>$('toast').classList.remove('visible'),3500); }
  async function request(url, options={}) {
    const response=await fetch(url,options);
    if (!response.ok){ let detail=`Ошибка HTTP ${response.status}`;try {detail=(await response.json()).detail||detail;}catch{}throw new Error(detail); }
    return response.json();
  }
  const jsonRequest=(url,method,body)=>request(url,{method,headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
  const edits = () => ({segments:state.project.segments,style:state.project.style,effects:state.project.effects});
  let saveTimer;
  async function save(silent=false){
    if(!state.project)return;
    clearTimeout(saveTimer); $('save-status').textContent='◌ Сохраняем…';
    try {const result=await jsonRequest(`/api/projects/${state.project.id}/edit`,'PUT',edits()); $('save-status').textContent='● Всё сохранено';if(!silent)notify('Проект сохранён');return result;}
    catch(err){ $('save-status').textContent='● Не сохранено'; notify('Не удалось сохранить: '+err.message);throw err; }
  }
  function scheduleSave(){clearTimeout(saveTimer);saveTimer=setTimeout(()=>save(true).catch(()=>{}),350);}
  function checkpoint(){state.history.push(JSON.stringify(edits()));if(state.history.length>30)state.history.shift();}
  function currentClip(){return state.project?.segments?.[state.selected];}
  function sourceToOutput(seconds){let elapsed=0;for(const seg of state.project.segments){if(seconds<seg.start)return elapsed;if(seconds<=seg.end)return elapsed+seconds-seg.start;elapsed+=seg.end-seg.start;}return elapsed;}
  function outputToSource(seconds){let elapsed=0;for(const seg of state.project.segments){const length=seg.end-seg.start;if(seconds<=elapsed+length)return seg.start+clamp(seconds-elapsed,0,length);elapsed+=length;}return state.project.segments.at(-1).end;}
  function seekToSource(t){if(!state.project)return;video.currentTime=clamp(t,0,state.project.duration);updateTime();}
  function currentOutput(){return state.project?sourceToOutput(video.currentTime):0;}
  function selectedByPosition(){if(!state.project)return;const i=state.project.segments.findIndex(s=>video.currentTime>=s.start-0.001&&video.currentTime<=s.end+0.001);if(i>=0)state.selected=i;}
  function updateTime(){
    $('timecode').textContent=`${fmt(currentOutput())} / ${fmt(outputLength())}`;
    if(!state.project)return;
    if (!video.paused && !video.seeking){
      const segments=state.project.segments;
      for(let i=0;i<segments.length;i++){
        if(video.currentTime>=segments[i].start-0.05 && video.currentTime<segments[i].end-0.05) { state.selected=i;break; }
        if(video.currentTime>=segments[i].end-0.05 && (i===segments.length-1||video.currentTime<segments[i+1].start)){
          if (i===segments.length-1){video.pause();$('play-button').textContent='▶';}
          else {video.currentTime=segments[i+1].start;state.selected=i+1;}
          break;
        }
      }
    }
  }
  function renderTimeline(){
    const p=state.project;
    $('clip-count').textContent=p?`${p.segments.length} клипов`:'0 клипов';
    $('timeline-length').textContent='Длина монтажа: '+fmt(outputLength());
    if(!p){ $('video-track').innerHTML='<div class="timeline-placeholder">Загрузи видео, чтобы увидеть дорожку</div>'; $('audio-track').innerHTML='<div class="timeline-placeholder">Добавленные звуки появятся здесь</div>';return; }
    const duration=Math.max(.01,outputLength());
    $('ruler').innerHTML=Array.from({length:5},(_,i)=>`<span>${fmt(duration*i/4)}</span>`).join('');
    $('video-track').innerHTML=p.segments.map((segment,i)=>`<div tabindex="0" role="button" title="${fmt(segment.start)} – ${fmt(segment.end)}" class="clip ${i===state.selected?'selected':''}" data-clip="${i}" style="width:calc(${((segment.end-segment.start)/duration*100).toFixed(5)}% - ${p.segments.length>1?2:0}px)"><small>▶ ${i+1}</small></div>`).join('');
    $('video-track').querySelectorAll('[data-clip]').forEach(el=>el.onclick=()=>{state.selected=+el.dataset.clip;seekToSource(p.segments[state.selected].start);refreshSelection();});
    $('audio-track').innerHTML=p.effects.length?p.effects.map((fx,i)=>{
      const label=state.assets.find(a=>a.id===fx.id)?.name||'SFX';
      return `<button class="sfx-pin" title="Нажми чтобы удалить эффект" style="left:${(fx.at/duration*100).toFixed(4)}%" data-sfx="${i}">♫ ${esc(label).slice(0,16)} ✕</button>`;
    }).join(''):'<div class="timeline-placeholder">Добавленные звуки появятся здесь</div>';
    $('audio-track').querySelectorAll('[data-sfx]').forEach(el=>el.onclick=()=>{checkpoint();p.effects.splice(+el.dataset.sfx,1);renderTimeline();scheduleSave();notify('Эффект удалён');});
  }
  function refreshSelection(){
    const seg=currentClip();
    $('trim-start').value=seg?seg.start.toFixed(2):'';
    $('trim-end').value=seg?seg.end.toFixed(2):'';
    $('video-track').querySelectorAll('[data-clip]').forEach(el=>el.classList.toggle('selected',+el.dataset.clip===state.selected));
  }
  function renderProject(){
    const p=state.project;
    $('empty-preview').classList.toggle('hidden',!!p);
    $('video-stage').classList.toggle('loaded',!!p);
    $('video-info').textContent=p?`${p.name} · ${fmt(p.duration)}`:'НЕТ МЕДИА';
    $('save-status').textContent=p?'● Всё сохранено':'● Локальный режим';
    $('style-grid').querySelectorAll('[data-style]').forEach(el=>el.classList.toggle('selected',el.dataset.style===(p?.style||'none')));
    renderTimeline();refreshSelection();updateTime();
  }
  async function openProject(id){
    try{const p=await request(`/api/projects/${id}`);state.project=p;state.selected=0;state.history=[];state.suggestions=p.suggestions||[];state.checked=state.suggestions.map(()=>true);
      video.pause();video.src=`/api/projects/${p.id}/media`;video.load();video.onloadedmetadata=()=>{seekToSource(p.segments[0].start);};
      renderProject();renderSuggestions();loadProjects(); notify(`Открыт проект: ${p.name}`);
    }catch(err){notify(err.message);}
  }
  async function loadProjects(){
    try{const projects=await request('/api/projects');$('project-list').innerHTML=projects.length?projects.map(p=>`<button class="project-entry ${p.id===state.project?.id?'current':''}" data-project="${p.id}"><span class="project-icon">▣</span><span>${esc(p.name)}</span></button>`).join(''):'<div class="muted mini">Пока нет проектов</div>';
      $('project-list').querySelectorAll('[data-project]').forEach(el=>el.onclick=()=>openProject(el.dataset.project));
    }catch{notify('Сервер не отвечает');}
  }
  async function uploadVideo(file){
    if(!file)return;
    notify('Загрузка видео. Большой файл может загружаться долго…');
    $('upload-start').disabled=true;
    try{const form=new FormData();form.append('file',file);const p=await request('/api/projects',{method:'POST',body:form});await openProject(p.id);}
    catch(err){notify('Ошибка загрузки: '+err.message);}finally{$('upload-start').disabled=false;}
  }
  function setMode(mode){state.mode=mode;$('mode-auto').classList.toggle('active',mode==='auto');$('mode-manual').classList.toggle('active',mode==='manual');$('auto-panel').classList.toggle('hidden',mode!=='auto');$('manual-panel').classList.toggle('hidden',mode!=='manual');}
  function subtractSilences(duration, ranges){
    let position=0;const result=[];
    for(const s of ranges.sort((a,b)=>a.start-b.start)){
      const left=clamp(s.start+0.07,0,duration),right=clamp(s.end-0.10,0,duration);
      if (left>position+.07)result.push({start:+position.toFixed(3),end:+left.toFixed(3)});
      position=Math.max(position,right);
    }
    if(duration>position+.07)result.push({start:+position.toFixed(3),end:+duration.toFixed(3)});
    return result;
  }
  function renderSuggestions(){
    const area=$('suggestions-area');if(!state.suggestions.length){area.innerHTML='<div class="tip"><span>✧</span>Нет найденных пауз. Попробуй другие настройки анализа.</div>';return;}
    area.innerHTML=`<div class="suggestions-head"><span>Найдено пауз: <strong>${state.suggestions.length}</strong></span><span>Выбери нужные</span></div><div class="suggestions-list">${state.suggestions.slice(0,200).map((s,i)=>`<div class="suggestion"><label><input type="checkbox" data-suggestion="${i}" ${state.checked[i]?'checked':''}/> ${fmt(s.start)} – ${fmt(s.end)}</label><span>${(s.end-s.start).toFixed(1)} c</span></div>`).join('')}</div><button class="btn btn-accent full" id="apply-suggestions">✂ Применить выбранные</button>`;
    area.querySelectorAll('[data-suggestion]').forEach(el=>el.onchange=()=>state.checked[+el.dataset.suggestion]=el.checked);
    $('apply-suggestions').onclick=()=>{
      const ranges=state.suggestions.filter((_,i)=>state.checked[i]);
      if(!ranges.length){notify('Не выбрано ни одной паузы');return;}
      const clips=subtractSilences(state.project.duration,ranges);
      if(!clips.length||clips.length>120){notify('Не удалось применить: слишком много клипов (максимум 120)');return;}
      checkpoint();state.project.segments=clips;state.selected=0;video.pause();seekToSource(clips[0].start);renderTimeline();refreshSelection();scheduleSave();setMode('manual');notify(`Монтаж создан: ${clips.length} клипов`);
    };
  }
  async function analyze(){
    if(!state.project){notify('Сначала загрузи видео');return;}
    const button=$('analyze-button');button.disabled=true;button.textContent='◌ Анализируем аудио…';
    try{const threshold=+$('sensitivity').value,minPause=+$('pause-length').value;const result=await request(`/api/projects/${state.project.id}/analyze?threshold=${threshold}&min_pause=${minPause}`,{method:'POST'});
      state.suggestions=result.suggestions;state.checked=state.suggestions.map(()=>true);state.project.suggestions=state.suggestions;renderSuggestions();notify(`Найдено пауз: ${result.suggestions.length}`);
    }catch(err){notify('Ошибка анализа: '+err.message);}finally{button.disabled=false;button.textContent='✦ Найти паузы';}
  }
  function splitClip(){
    if(!state.project){notify('Сначала загрузи видео');return;}
    const t=video.currentTime;
    const index=state.project.segments.findIndex(s=>t>s.start+.07&&t<s.end-.07);
    if(index===-1){notify('Поставь курсор внутри клипа');return;}
    if(state.project.segments.length>=120){notify('Максимум 120 клипов');return;}
    checkpoint();const old=state.project.segments[index];state.project.segments.splice(index,1,{start:old.start,end:+t.toFixed(3)},{start:+t.toFixed(3),end:old.end});state.selected=index+1;renderTimeline();refreshSelection();scheduleSave();notify('Клип разделён');
  }
  function deleteClip(){
    if(!state.project)return;
    if(state.project.segments.length===1){notify('Нельзя удалить последний клип');return;}
    checkpoint();state.project.segments.splice(state.selected,1);state.selected=clamp(state.selected,0,state.project.segments.length-1);seekToSource(currentClip().start);renderTimeline();refreshSelection();scheduleSave();notify('Клип удалён');
  }
  function undo(){
    if(!state.project||!state.history.length){notify('Нет действий для отмены');return;}
    Object.assign(state.project,JSON.parse(state.history.pop()));state.selected=0;seekToSource(currentClip().start);renderProject();scheduleSave();notify('Действие отменено');
  }
  function trim(){
    if(!state.project)return;
    const seg=currentClip(),start=+$('trim-start').value,end=+$('trim-end').value,i=state.selected;
    if(!Number.isFinite(start)||!Number.isFinite(end)||end-start<.06||start<0||end>state.project.duration ||(i>0&&start<state.project.segments[i-1].end-.001)||(i<state.project.segments.length-1&&end>state.project.segments[i+1].start+.001)){
      notify('Проверь границы: клипы не должны пересекаться');return;
    }
    checkpoint();seg.start=start;seg.end=end;seekToSource(start);renderTimeline();refreshSelection();scheduleSave();notify('Границы изменены');
  }
  async function loadEffects(){try{state.assets=await request('/api/effects');$('effect-count').textContent=state.assets.length;$('effect-list').innerHTML=state.assets.length?state.assets.map(a=>`<div class="effect-entry"><div><strong title="${esc(a.name)}">♫ ${esc(a.name)}</strong><small>Звуковой эффект</small></div><button data-effect="${a.id}" title="Добавить к видео">＋</button></div>`).join(''):'<div class="muted mini">Пока нет эффектов</div>';
    $('effect-list').querySelectorAll('[data-effect]').forEach(el=>el.onclick=()=>{
      if(!state.project){notify('Сначала загрузи видео');return;}
      if(state.project.effects.length>=40){notify('Максимум 40 звуковых эффектов');return;}
      checkpoint();state.project.effects.push({id:el.dataset.effect,at:Math.max(0,Math.round(currentOutput()*100)/100),volume:0.65});renderTimeline();scheduleSave();notify('Эффект добавлен в момент '+fmt(currentOutput()));
    });}catch(err){notify(err.message);}}
  async function uploadEffects(files){
    const items=[...files].filter(f=>/\.(wav|mp3|ogg|m4a|aac)$/i.test(f.name));
    if(!items.length){notify('В папке нет поддерживаемых звуков');return;}
    let successes=0;
    for(const file of items){try{const form=new FormData();form.append('file',file);await request('/api/effects',{method:'POST',body:form});successes++;}catch(err){notify('Ошибка эффекта '+file.name+': '+err.message);}}
    await loadEffects();notify(`В библиотеку добавлено звуков: ${successes}`);
  }
  async function exportVideo(){
    if(!state.project){notify('Сначала загрузи видео');return;}
    try{await save(true);const job=await jsonRequest(`/api/projects/${state.project.id}/render`,'POST',edits());state.job=job.id;
      $('export-modal').classList.remove('hidden');$('download-link').classList.add('hidden');$('export-title').textContent='Экспорт видео';$('export-subtitle').textContent='Создаём MP4 с твоими правками';$('export-progress').style.width='0%';$('progress-label').textContent='0%';
      pollJob(job.id);
    }catch(err){notify('Ошибка экспорта: '+err.message);}
  }
  async function pollJob(id){
    if(state.job!==id)return;
    try{const result=await request(`/api/jobs/${id}`);$('export-progress').style.width=result.progress+'%';$('progress-label').textContent=result.progress+'%';
      if(result.state==='done'){$('export-title').textContent='Готово!';$('export-subtitle').textContent='Монтаж успешно обработан';$('download-link').href=`/api/jobs/${id}/download`;$('download-link').classList.remove('hidden');return;}
      if(result.state==='error'){$('export-title').textContent='Ошибка экспорта';$('export-subtitle').textContent=result.error;$('progress-label').textContent='Не удалось обработать';return;}
      setTimeout(()=>pollJob(id),1200);
    }catch(err){$('export-title').textContent='Связь с сервером потеряна';$('export-subtitle').textContent=err.message;}
  }
  function bind(){
    $('upload-start').onclick=()=>$('video-file').click();$('video-file').onchange=e=>uploadVideo(e.target.files[0]);
    const stage=$('video-stage');stage.ondragover=e=>{e.preventDefault();stage.classList.add('dragover');};stage.ondragleave=e=>{if(!stage.contains(e.relatedTarget))stage.classList.remove('dragover');};stage.ondrop=e=>{e.preventDefault();stage.classList.remove('dragover');const f=[...e.dataTransfer.files].find(f=>/\.(mp4|mov|mkv|webm|m4v)$/i.test(f.name));uploadVideo(f);};
    $('mode-auto').onclick=()=>setMode('auto');$('mode-manual').onclick=()=>setMode('manual');
    $('nav-editor').onclick=()=>window.scrollTo({top:0,behavior:'smooth'});$('nav-projects').onclick=()=>{$('project-list').scrollIntoView({behavior:'smooth'});notify('Выбери проект из списка слева');};$('nav-effects').onclick=()=>{$('effect-list').scrollIntoView({behavior:'smooth'});};
    $('refresh-projects').onclick=loadProjects;$('save-project').onclick=()=>save().catch(()=>{});$('analyze-button').onclick=analyze;
    $('sensitivity').oninput=e=>$('sensitivity-label').textContent=e.target.value+' dB';$('pause-length').oninput=e=>$('pause-label').textContent=Number(e.target.value).toFixed(1)+' c';
    $('play-button').onclick=()=>{if(!state.project)return;if(video.paused){const current=state.project.segments.find(s=>video.currentTime>=s.start&&video.currentTime<s.end-.05);if(!current)seekToSource(state.project.segments[0].start);video.play().catch(err=>notify(err.message));}else video.pause();};
    video.onplay=()=>$('play-button').textContent='Ⅱ';video.onpause=()=>$('play-button').textContent='▶';video.ontimeupdate=updateTime;
    $('back-five').onclick=()=>state.project&&seekToSource(outputToSource(clamp(currentOutput()-5,0,outputLength())));
    $('next-five').onclick=()=>state.project&&seekToSource(outputToSource(clamp(currentOutput()+5,0,outputLength())));
    $('mute-button').onclick=()=>{video.muted=!video.muted;$('mute-button').textContent=video.muted?'◖×':'◖))';};
    $('split-button').onclick=splitClip;$('delete-button').onclick=deleteClip;$('undo-button').onclick=undo;$('apply-trim').onclick=trim;
    $('reset-button').onclick=()=>{if(!state.project)return;checkpoint();state.project.segments=[{start:0,end:state.project.duration}];state.selected=0;renderProject();scheduleSave();notify('Оригинальный монтаж восстановлен');};
    $('style-grid').querySelectorAll('[data-style]').forEach(el=>el.onclick=()=>{if(!state.project){notify('Сначала загрузи видео');return;}checkpoint();state.project.style=el.dataset.style;renderProject();scheduleSave();notify('Пресет будет применён при экспорте');});
    $('add-effects').onclick=()=>$('effect-files').click();$('effect-files').onchange=e=>uploadEffects(e.target.files);$('add-folder').onclick=()=>$('effect-folder').click();$('effect-folder').onchange=e=>uploadEffects(e.target.files);
    $('export-button').onclick=exportVideo;$('close-modal').onclick=()=>$('export-modal').classList.add('hidden');
    window.addEventListener('keydown',e=>{if(['INPUT','TEXTAREA'].includes(document.activeElement.tagName))return;if(e.code==='Space'){e.preventDefault();$('play-button').click();}if(e.code==='KeyS'&&(e.ctrlKey||e.metaKey)){e.preventDefault();save().catch(()=>{});}if(e.code==='KeyK'){e.preventDefault();splitClip();}});
  }
  bind();loadProjects();loadEffects();renderProject();
})();
