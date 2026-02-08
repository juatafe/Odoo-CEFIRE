# Gestió de Responsabilitat Patrimonial

:::{raw} html
<style>
  #rp-app { margin: 1rem 0; isolation: isolate; font-family: Arial, sans-serif; text-align: center; }
  #rp-app .rp-progressbar{ display:flex; justify-content:space-between; list-style:none; padding:0; margin:0 0 20px; counter-reset: rp-step; }
  #rp-app .rp-progress-step{ flex-grow:1; position:relative; text-align:center; cursor:pointer; }
  #rp-app .rp-progress-step:before{ content: counter(rp-step); counter-increment: rp-step; width:30px; height:30px; border:2px solid #ccc;
     display:block; text-align:center; margin:0 auto 10px; border-radius:50%; line-height:30px; background:#fff; }
  #rp-app .rp-progress-step:after{ content:''; position:absolute; width:100%; height:2px; background:#ccc; top:14px; left:-50%; z-index:-1; }
  #rp-app .rp-progress-step:first-child:after{ content:none; }
  #rp-app .rp-progress-step.active:before, #rp-app .rp-progress-step.completed:before{ background:#007bff; border-color:#007bff; color:#fff; }
  #rp-app .rp-progress-step.completed:after{ background:#007bff; }
  #rp-app .rp-step-content{ display:none; padding:20px; margin-top:20px; background:#fff; border:1px solid #ccc; border-radius:5px; text-align:left; }
  #rp-app .rp-step-content.active{ display:block; }
  #rp-app .rp-btn{ padding:10px 20px; margin:10px; background:#007bff; color:#fff; border:0; border-radius:5px; cursor:pointer; }
  #rp-app .rp-btn:hover{ background:#0056b3; }
  #rp-app input, #rp-app select, #rp-app textarea{ width:100%; padding:8px; margin-top:5px; margin-bottom:10px; border:1px solid #ccc; border-radius:5px; }
  #rp-app .rp-hidden{ display:none; }
  #rp-app .rp-type-damage{ display:flex; justify-content:space-around; flex-wrap:wrap; margin-top:10px; }
  #rp-app .rp-type-damage > div{ flex:1; min-width:150px; margin:10px; }
  #rp-app .rp-damage-info{ text-align:left; }
  #rp-app .rp-checks{ display:flex; justify-content:space-around; flex-wrap:wrap; }
</style>

<section id="rp-app">

  <ul class="rp-progressbar">
    <li class="rp-progress-step active" data-step="1">Inici</li>
    <li class="rp-progress-step" data-step="2">Revisió</li>
    <li class="rp-progress-step" data-step="3">Enviament</li>
    <li class="rp-progress-step" data-step="4">Revisió Informes</li>
    <li class="rp-progress-step" data-step="5">Resolució</li>
    <li class="rp-progress-step" data-step="6">Tancament</li>
  </ul>

  <!-- PAS 1 -->
  <div class="rp-step-content active" data-step="1">
    <h2>Pas 1: Iniciar Reclamació</h2>
    <input type="text" id="rp-solicitant-nom" placeholder="Nom del Sol·licitant" required>
    <input type="text" id="rp-solicitant-dni" placeholder="DNI" required>
    <textarea id="rp-reclamacio-descripcio" placeholder="Descripció de la Reclamació" required></textarea>
    <p>Seleccioneu el tipus de danys:</p>
    <div class="rp-type-damage">
      <div>
        <input type="checkbox" id="rp-persona" value="persona">
        <label for="rp-persona">Danys a Persona</label>
        <div id="rp-persona-documents" class="rp-hidden rp-damage-info">
          <p>Aporteu els següents documents:</p>
          <input type="file" id="rp-informe-medico" required>
          <label for="rp-informe-medico">Informe Mèdic</label><br>
          <input type="file" id="rp-justificant-despeses" required>
          <label for="rp-justificant-despeses">Justificant de Despeses Mèdiques</label><br>
        </div>
      </div>
      <div>
        <input type="checkbox" id="rp-vehicle" value="vehicle">
        <label for="rp-vehicle">Danys a Vehicle</label>
        <div id="rp-vehicle-documents" class="rp-hidden rp-damage-info">
          <p>Aporteu la següent informació:</p>
          <label for="rp-vehicle_type">Tipus de Vehicle:</label>
          <input type="text" id="rp-vehicle_type" required><br>
          <label for="rp-vehicle_damage">Descripció dels Danys:</label>
          <textarea id="rp-vehicle_damage" required></textarea><br>
          <label for="rp-incident_location">Lloc de l'Incident:</label>
          <input type="text" id="rp-incident_location" required><br>
          <label for="rp-incident_time">Hora de l'Incident:</label>
          <input type="time" id="rp-incident_time" required><br>
        </div>
      </div>
      <div>
        <input type="checkbox" id="rp-edifici" value="edifici">
        <label for="rp-edifici">Danys a Edifici Particular</label>
        <div id="rp-edifici-documents" class="rp-hidden rp-damage-info">
          <p>Aporteu la següent informació:</p>
          <label for="rp-building_damage">Descripció dels Danys:</label>
          <textarea id="rp-building_damage" required></textarea><br>
          <label for="rp-building_location">Lloc de l'Incident:</label>
          <input type="text" id="rp-building_location" required><br>
          <label for="rp-building_photos">Fotos del Dany:</label>
          <input type="file" id="rp-building_photos" accept="image/*" multiple required><br>
        </div>
      </div>
      <div>
        <input type="checkbox" id="rp-be" value="be">
        <label for="rp-be">Danys a Bé Concessionat</label>
        <div id="rp-be-documents" class="rp-hidden rp-damage-info">
          <p>Aporteu la següent informació:</p>
          <label for="rp-concession_damage">Descripció dels Danys:</label>
          <textarea id="rp-concession_damage" required></textarea><br>
          <label for="rp-concession_location">Lloc de l'Incident:</label>
          <input type="text" id="rp-concession_location" required><br>
          <label for="rp-concession_photos">Fotos del Dany:</label>
          <input type="file" id="rp-concession_photos" accept="image/*" multiple required><br>
        </div>
      </div>
    </div>
    <button type="button" class="rp-btn" data-action="next">Continuar</button>
  </div>

  <!-- PAS 2 -->
  <div class="rp-step-content" data-step="2">
    <h2>Pas 2: Revisió del TAG</h2>
    <p>Aquesta reclamació requereix diversos informes. Si us plau, confirmeu que la documentació està completa:</p>
    <div class="rp-checks">
      <div><input type="checkbox" id="rp-doc_persona"><label for="rp-doc_persona">Documentació Danys a Persona Completa</label></div>
      <div><input type="checkbox" id="rp-doc_vehicle"><label for="rp-doc_vehicle">Documentació Danys a Vehicle Completa</label></div>
      <div><input type="checkbox" id="rp-doc_edifici"><label for="rp-doc_edifici">Documentació Danys a Edifici Completa</label></div>
      <div><input type="checkbox" id="rp-doc_be"><label for="rp-doc_be">Documentació Danys a Bé Concessionat Completa</label></div>
    </div>
    <button type="button" class="rp-btn" data-action="next">Continuar</button>
  </div>

  <!-- PAS 3 -->
  <div class="rp-step-content" data-step="3">
    <h2>Pas 3: Enviament als Rols</h2>
    <ul id="rp-rols-list"></ul>
    <button type="button" class="rp-btn" data-action="next">Continuar</button>
  </div>

  <!-- PAS 4 -->
  <div class="rp-step-content" data-step="4">
    <h2>Pas 4: Recepció dels Informes</h2>
    <select id="rp-rol-select">
      <option value="">Seleccioneu un rol</option>
      <option value="tag">TAG</option>
      <option value="policia">Policia</option>
      <option value="tecnic_vehicles">Tècnic de Vehicles</option>
      <option value="arquitecte">Arquitecte</option>
      <option value="brigada">Brigada Municipal</option>
      <option value="concessionaria">Concessionària</option>
    </select>
    <div id="rp-rol-tasks" class="rp-hidden"></div>
    <button type="button" class="rp-btn" data-action="next">Continuar</button>
  </div>

  <!-- PAS 5 -->
  <div class="rp-step-content" data-step="5">
    <h2>Pas 5: Resolució</h2>
    <select id="rp-resolucio"><option value="favorable">Favorable</option><option value="desfavorable">Desfavorable</option></select>
    <textarea id="rp-resum" placeholder="Resum de la reclamació i la resolució"></textarea>
    <button type="button" class="rp-btn" data-action="gen">Enviar Resolució</button>
  </div>

  <!-- PAS 6 -->
  <div class="rp-step-content" data-step="6">
    <h2>Pas 6: Tancament</h2>
    <div id="rp-final"></div>
    <button type="button" class="rp-btn" data-action="reset">Nova Reclamació</button>
  </div>
</section>

<script>
(function(){
  const app=document.getElementById('rp-app'); if(!app) return;
  let currentStep=1; let informesRebuts=[];
  const $=(s)=>app.querySelector(s); const $$=(s)=>app.querySelectorAll(s);

  function showStep(s){
    $$('.rp-progress-step').forEach(e=>e.classList.remove('active','completed'));
    $$('.rp-step-content').forEach(e=>e.classList.remove('active'));
    const p=app.querySelector('.rp-progress-step[data-step="'+s+'"]');
    const c=app.querySelector('.rp-step-content[data-step="'+s+'"]');
    if(p) p.classList.add('active'); if(c) c.classList.add('active');
    for(let i=1;i<s;i++){
      const pi=app.querySelector('.rp-progress-step[data-step="'+i+'"]');
      if(pi) pi.classList.add('completed');
    }
    currentStep=s;
  }

  function nextStep(){
    if(currentStep<6){
      const next=currentStep+1;
      showStep(next);
      if(next===3) updateRolsList();
      if(next===4) updateInformesList();
    }
  }

  function updateRolsList(){
    const sel=$$('.rp-type-damage input:checked'); const list=$('#rp-rols-list'); list.innerHTML='';
    sel.forEach(t=>{
      let rols='';
      if(t.value==='persona') rols='Policia';
      if(t.value==='vehicle') rols='Policia, Tècnic de Vehicles';
      if(t.value==='edifici') rols='Policia, Arquitecte, Brigada Municipal';
      if(t.value==='be') rols='Policia, Concessionària, Brigada Municipal';
      rols.split(', ').forEach(r=>{
        const li=document.createElement('li');
        li.textContent=`${r} (per a ${t.labels[0].innerText})`;
        list.appendChild(li);
      });
    });
  }

  function updateInformesList(){
    const sel=$$('.rp-type-damage input:checked');
    let informesList=$('#rp-informes-list');
    if(!informesList){
      informesList=document.createElement('div');
      informesList.id='rp-informes-list';
      app.appendChild(informesList);
    }
    informesList.innerHTML='';
    sel.forEach(t=>{
      let informe='';
      switch(t.value){
        case 'persona': informe='Informe Policial'; break;
        case 'vehicle': informe='Informe Policial, Informe Tècnic del Vehicle'; break;
        case 'edifici': informe='Informe Policial, Informe d\'Arquitecte, Informe Brigada'; break;
        case 'be': informe='Informe Policial, Informe Concessionària, Informe Brigada'; break;
      }
      const div=document.createElement('div');
      div.innerHTML=`<input type="checkbox" class="rp-informe-check" id="${t.value}-informe">
                      <label for="${t.value}-informe">${informe}</label>`;
      informesList.appendChild(div);
    });
  }

  function showRoleTasks(){
    const roleTasks=$('#rp-rol-tasks');
    const selectedRole=$('#rp-rol-select').value;
    roleTasks.classList.add('rp-hidden');
    roleTasks.innerHTML='';
    if(selectedRole){
      const tasks=document.createElement('div');
      switch(selectedRole){
        case 'policia': tasks.innerHTML='<h3>Policia</h3><p>Detalls incident…</p>'; break;
        case 'tecnic_vehicles': tasks.innerHTML='<h3>Tècnic Vehicles</h3><p>Valoració danys…</p>'; break;
        case 'arquitecte': tasks.innerHTML='<h3>Arquitecte</h3><p>Inspecció lloc…</p>'; break;
        case 'brigada': tasks.innerHTML='<h3>Brigada Municipal</h3><p>Verificació reparacions…</p>'; break;
        case 'concessionaria': tasks.innerHTML='<h3>Concessionària</h3><p>Valoració i reparacions…</p>'; break;
        case 'tag': tasks.innerHTML='<h3>TAG</h3><p>Confirmar recepció informes…</p>'; break;
      }
      roleTasks.appendChild(tasks);
      roleTasks.classList.remove('rp-hidden');
    }
  }

  function generateResolution(){
    const nom=$('#rp-solicitant-nom').value;
    const dni=$('#rp-solicitant-dni').value;
    const desc=$('#rp-reclamacio-descripcio').value;
    informesRebuts=Array.from($$('.rp-informe-check:checked')).map(i=>i.value);
    $('#rp-final').innerHTML=`<h3>Resolució</h3>
      <p><strong>Reclamant:</strong> ${nom} (DNI: ${dni})</p>
      <p><strong>Descripció:</strong> ${desc}</p>
      <p><strong>Informes rebuts:</strong> ${informesRebuts.join(', ')}</p>
      <p><strong>Resolució:</strong> ${$('#rp-resolucio').value}</p>
      <p><strong>Resum:</strong> ${$('#rp-resum').value}</p>`;
    nextStep();
  }

  function resetProcess(){ showStep(1); }

  app.addEventListener('change',e=>{
    if(e.target.id==='rp-rol-select') showRoleTasks();
  });

  app.addEventListener('click',e=>{
    const a=e.target.closest('[data-action]');
    if(a&&a.dataset.action==='next') nextStep();
    if(a&&a.dataset.action==='gen') generateResolution();
    if(a&&a.dataset.action==='reset') resetProcess();
  });

  showStep(1);
})();
</script>
:::
