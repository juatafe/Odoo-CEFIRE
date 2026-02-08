# Gestió de Responsabilitat Patrimonial (Demo incrustada)

Aquest exemple mostra l'aplicació incrustada dins d'un fitxer `.md` usant **MyST** i HTML cru.

:::{raw} html
<!-- Widget escopat: Gestió de Responsabilitat Patrimonial -->
<style>
  /* Escopem tot dins del contenidor #rp-app */
  #rp-app { margin: 1rem 0; isolation: isolate; }
  #rp-app .rp-progressbar{
    display:flex; justify-content:space-between; list-style:none; padding:0; margin:0 0 20px;
    counter-reset: rp-step;
  }
  #rp-app .rp-progress-step{ flex-grow:1; position:relative; text-align:center; cursor:pointer; }
  #rp-app .rp-progress-step:before{
    content: counter(rp-step);
    counter-increment: rp-step;
    width:30px; height:30px; border:2px solid #ccc; display:block; text-align:center;
    margin:0 auto 10px; border-radius:50%; line-height:30px; background:#fff;
  }
  #rp-app .rp-progress-step:after{
    content:''; position:absolute; width:100%; height:2px; background:#ccc; top:14px; left:-50%; z-index:-1;
  }
  #rp-app .rp-progress-step:first-child:after{ content:none; }
  #rp-app .rp-progress-step.active:before,
  #rp-app .rp-progress-step.completed:before{ background:#007bff; border-color:#007bff; color:#fff; }
  #rp-app .rp-progress-step.completed:after{ background:#007bff; }

  #rp-app .rp-step-content{
    display:none; padding:20px; margin-top:20px; background:#fff; border:1px solid #ccc; border-radius:5px;
  }
  #rp-app .rp-step-content.active{ display:block; }

  #rp-app .rp-btn{
    padding:10px 20px; margin:10px; background:#007bff; color:#fff; border:0; border-radius:5px; cursor:pointer;
  }
  #rp-app .rp-btn:hover{ background:#0056b3; }

  #rp-app input, #rp-app select, #rp-app textarea{
    width:100%; padding:8px; margin-top:5px; margin-bottom:10px; border:1px solid #ccc; border-radius:5px;
  }

  #rp-app .rp-hidden{ display:none; }

  #rp-app .rp-type-damage{ display:flex; justify-content:space-around; flex-wrap:wrap; margin-top:10px; }
  #rp-app .rp-type-damage > div{ flex:1; min-width:150px; margin:10px; }
  #rp-app .rp-damage-info{ text-align:left; }
  #rp-app .rp-checks{ display:flex; justify-content:space-around; flex-wrap:wrap; }
</style>

<section id="rp-app" aria-label="Gestió de Responsabilitat Patrimonial">
  <h2>Gestió de Responsabilitat Patrimonial</h2>

  <ul class="rp-progressbar">
    <li class="rp-progress-step active" data-step="1">Inici</li>
    <li class="rp-progress-step" data-step="2">Revisió</li>
    <li class="rp-progress-step" data-step="3">Enviament</li>
    <li class="rp-progress-step" data-step="4">Revisió Informes</li>
    <li class="rp-progress-step" data-step="5">Resolució</li>
    <li class="rp-progress-step" data-step="6">Tancament</li>
  </ul>

  <div class="rp-step-content active" data-step="1">
    <h3>Pas 1: Iniciar Reclamació</h3>
    <input type="text" id="rp-solicitant-nom" placeholder="Nom del Sol·licitant" required>
    <input type="text" id="rp-solicitant-dni" placeholder="DNI" required>
    <textarea id="rp-reclamacio-descripcio" placeholder="Descripció de la Reclamació" required></textarea>
    <p>Seleccioneu el tipus de danys:</p>
    <div class="rp-type-damage">
      <div>
        <input type="checkbox" id="rp-persona" value="persona">
        <label for="rp-persona">Danys a Persona</label>
        <div id="rp-persona-docs" class="rp-hidden rp-damage-info">
          <p>Aporteu els següents documents:</p>
          <input type="file" id="rp-informe-medico" required>
          <label for="rp-informe-medico">Informe Mèdic</label><br>
          <input type="file" id="rp-justificant-despeses" required>
          <label for="rp-justificant-despeses">Justificant de Despeses Mèdiques</label><br>
        </div>
      </div>
      <!-- ... Altres blocs de danys com vehicle, edifici i bé concessionat ... -->
    </div>
    <button type="button" class="rp-btn" data-action="next">Continuar</button>
  </div>

  <!-- Resta dels passos igual que al codi anterior -->
</section>

<script>
// JS encapsulat dins de (function(){...}) per no contaminar global
(function(){
  const app=document.getElementById('rp-app');
  if(!app) return;
  let currentStep=1;
  const $=(sel)=>app.querySelector(sel);
  const $$=(sel)=>app.querySelectorAll(sel);
  function showStep(s){$$('.rp-progress-step').forEach(e=>e.classList.remove('active','completed'));
    $$('.rp-step-content').forEach(e=>e.classList.remove('active'));
    const p=app.querySelector('.rp-progress-step[data-step="'+s+'"]');
    const c=app.querySelector('.rp-step-content[data-step="'+s+'"]');
    if(p) p.classList.add('active'); if(c) c.classList.add('active');
    for(let i=1;i<s;i++){const pi=app.querySelector('.rp-progress-step[data-step="'+i+'"]'); if(pi) pi.classList.add('completed');}
    currentStep=s;}
  function nextStep(){if(currentStep<6){showStep(currentStep+1);}}
  app.addEventListener('click',e=>{const a=e.target.closest('[data-action]');if(a&&a.dataset.action==='next')nextStep();
  const step=e.target.closest('.rp-progress-step')?.dataset.step;if(step)showStep(parseInt(step,10));});
  showStep(currentStep);
})();
</script>
:::
