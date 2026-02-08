# Gestió de Responsabilitat Patrimonial (versió escopada)

Aquesta versió està encapsulada dins `#rp-app` per evitar que els estils i scripts afecten
altres parts del tema o del sidebar.

::{raw} html
<!DOCTYPE html>
<html lang="ca">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gestió de Responsabilitat Patrimonial</title>
    <style>
        #rp-app {
            font-family: Arial, sans-serif;
            background-color: #f4f4f4;
            margin: 0;
            padding: 20px;
            text-align: center;
        }
        #rp-app h1 {
            color: #333;
        }
        #rp-app .rp-rp-progressbar {
            display: flex;
            justify-content: space-between;
            list-style: none;
            padding: 0;
            margin-bottom: 20px;
            counter-reset: step;
        }
        #rp-app .rp-rp-progress-step {
            flex-grow: 1;
            position: relative;
            text-align: center;
            cursor: pointer;
        }
        #rp-app .rp-rp-progress-step:before {
            content: counter(step);
            counter-increment: step;
            width: 30px;
            height: 30px;
            border: 2px solid #ccc;
            display: block;
            text-align: center;
            margin: 0 auto 10px;
            border-radius: 50%;
            line-height: 30px;
            background-color: #fff;
        }
        #rp-app .rp-rp-progress-step:after {
            content: '';
            position: absolute;
            width: 100%;
            height: 2px;
            background-color: #ccc;
            top: 14px;
            left: -50%;
            z-index: -1;
        }
        #rp-app .rp-rp-progress-step:first-child:after {
            content: none;
        }
        #rp-app .rp-rp-progress-step.active:before, #rp-app .rp-rp-progress-step.completed:before {
            background-color: #007bff;
            border-color: #007bff;
            color: white;
        }
        #rp-app .rp-rp-progress-step.completed:after {
            background-color: #007bff;
        }
        #rp-app .rp-rp-step-content {
            display: none;
            padding: 20px;
            margin-top: 20px;
            background-color: white;
            border: 1px solid #ccc;
            border-radius: 5px;
        }
        #rp-app .rp-rp-step-content.active {
            display: block;
        }
        #rp-app button {
            padding: 10px 20px;
            margin: 10px;
            background-color: #007bff;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
        }
        #rp-app button:hover {
            background-color: #0056b3;
        }
        #rp-app input, #rp-app select, #rp-app textarea {
            width: 100%;
            padding: 8px;
            margin-top: 5px;
            margin-bottom: 10px;
            border: 1px solid #ccc;
            border-radius: 5px;
        }
        #rp-app .rp-rp-hidden {
            display: none;
        }
        #rp-app .rp-type-damage {
            display: flex;
            justify-content: space-around;
            flex-wrap: wrap;
            margin-top: 10px;
        }
        #rp-app .rp-type-damage div {
            flex: 1;
            min-width: 150px;
            margin: 10px;
        }
        #rp-app .rp-rp-damage-info {
            text-align: left;
        }
        #rp-app .rp-checks {
            display: flex;
            justify-content: space-around;
            flex-wrap: wrap;
        }
    </style>
</head>
<#rp-app>
<section id="rp-app">
    <#rp-app h1>Gestió de Responsabilitat Patrimonial</#rp-app h1>
    <ul class="rp-progressbar">
        <li class="rp-progress-step active" data-step="1">Inici</li>
        <li class="rp-progress-step" data-step="2">Revisió</li>
        <li class="rp-progress-step" data-step="3">Enviament</li>
        <li class="rp-progress-step" data-step="4">Revisió Informes</li>
        <li class="rp-progress-step" data-step="5">Resolució</li>
        <li class="rp-progress-step" data-step="6">Tancament</li>
    </ul>

    <!-- Continguts dels passos -->
    <div class="rp-step-content active" data-step="1">
        <h2>Pas 1: Iniciar Reclamació</h2>
        <#rp-app input type="text" id="solicitant-nom" placeholder="Nom del Sol·licitant" required>
        <#rp-app input type="text" id="solicitant-dni" placeholder="DNI" required>
        <#rp-app textarea id="reclamacio-descripcio" placeholder="Descripció de la Reclamació" required></#rp-app textarea>
        <p>Seleccioneu el tipus de danys:</p>
        <div class="rp-type-damage">
            <div>
                <#rp-app input type="checkbox" id="persona" value="persona" onchange="togglePersonaDocuments()">
                <label for="persona">Danys a Persona</label>
                <div id="persona-documents" class="rp-hidden rp-damage-info">
                    <p>Aporteu els següents documents:</p>
                    <#rp-app input type="file" id="informe_medico" required>
                    <label for="informe_medico">Informe Mèdic</label><br>
                    <#rp-app input type="file" id="justificant_despeses" required>
                    <label for="justificant_despeses">Justificant de Despeses Mèdiques</label><br>
                </div>
            </div>
            <div>
                <#rp-app input type="checkbox" id="vehicle" value="vehicle" onchange="toggleVehicleDocuments()">
                <label for="vehicle">Danys a Vehicle</label>
                <div id="vehicle-documents" class="rp-hidden rp-damage-info">
                    <p>Aporteu la següent informació:</p>
                    <label for="vehicle_type">Tipus de Vehicle:</label>
                    <#rp-app input type="text" id="vehicle_type" required><br>
                    <label for="vehicle_damage">Descripció dels Danys:</label>
                    <#rp-app textarea id="vehicle_damage" required></#rp-app textarea><br>
                    <label for="incident_location">Lloc de l'Incident:</label>
                    <#rp-app input type="text" id="incident_location" required><br>
                    <label for="incident_time">Hora de l'Incident:</label>
                    <#rp-app input type="time" id="incident_time" required><br>
                </div>
            </div>
            <div>
                <#rp-app input type="checkbox" id="edifici" value="edifici" onchange="toggleEdificiDocuments()">
                <label for="edifici">Danys a Edifici Particular</label>
                <div id="edifici-documents" class="rp-hidden rp-damage-info">
                    <p>Aporteu la següent informació:</p>
                    <label for="building_damage">Descripció dels Danys:</label>
                    <#rp-app textarea id="building_damage" required></#rp-app textarea><br>
                    <label for="building_location">Lloc de l'Incident:</label>
                    <#rp-app input type="text" id="building_location" required><br>
                    <label for="building_photos">Fotos del Dany:</label>
                    <#rp-app input type="file" id="building_photos" accept="image/*" multiple required><br>
                </div>
            </div>
            <div>
                <#rp-app input type="checkbox" id="be" value="be" onchange="toggleBeDocuments()">
                <label for="be">Danys a Bé Concessionat</label>
                <div id="be-documents" class="rp-hidden rp-damage-info">
                    <p>Aporteu la següent informació:</p>
                    <label for="concession_damage">Descripció dels Danys:</label>
                    <#rp-app textarea id="concession_damage" required></#rp-app textarea><br>
                    <label for="concession_location">Lloc de l'Incident:</label>
                    <#rp-app input type="text" id="concession_location" required><br>
                    <label for="concession_photos">Fotos del Dany:</label>
                    <#rp-app input type="file" id="concession_photos" accept="image/*" multiple required><br>
                </div>
            </div>
        </div>
        <#rp-app button type="#rp-app button" onclick="nextStep()">Continuar</#rp-app button>
    </div>

    <div class="rp-step-content" data-step="2">
        <h2>Pas 2: Revisió del TAG</h2>
        <p>Aquesta reclamació requereix diversos informes. Si us plau, confirmeu que la documentació està completa:</p>
        <div class="rp-checks">
            <div>
                <#rp-app input type="checkbox" id="doc_persona" class="tag-check" data-doc="persona">
                <label for="doc_persona">Documentació Danys a Persona Completa</label><br>
            </div>
            <div>
                <#rp-app input type="checkbox" id="doc_vehicle" class="tag-check" data-doc="vehicle">
                <label for="doc_vehicle">Documentació Danys a Vehicle Completa</label><br>
            </div>
            <div>
                <#rp-app input type="checkbox" id="doc_edifici" class="tag-check" data-doc="edifici">
                <label for="doc_edifici">Documentació Danys a Edifici Completa</label><br>
            </div>
            <div>
                <#rp-app input type="checkbox" id="doc_be" class="tag-check" data-doc="be">
                <label for="doc_be">Documentació Danys a Bé Concessionat Completa</label><br>
            </div>
        </div>
        <#rp-app button type="#rp-app button" onclick="nextStep()">Continuar</#rp-app button>
    </div>

    <div class="rp-step-content" data-step="3">
        <h2>Pas 3: Enviament als Rols</h2>
        <p>La reclamació s'ha enviat als següents rols per a completar els informes necessaris:</p>
        <ul id="rols-list">
            <!-- Els rols es mostraran aquí dinàmicament -->
        </ul>
        <#rp-app button type="#rp-app button" onclick="nextStep()">Continuar</#rp-app button>
    </div>

    <div class="rp-step-content" data-step="4">
        <h2>Pas 4: Recepció dels Informes</h2>
        <p>Seleccioneu el vostre rol per veure les tasques assignades:</p>
        <#rp-app select id="rol-#rp-app select" onchange="showRoleTasks()">
            <option value="">Seleccioneu un rol</option>
            <option value="tag">TAG</option>
            <option value="policia">Policia</option>
            <option value="tecnic_vehicles">Tècnic de Vehicles</option>
            <option value="arquitecte">Arquitecte</option>
            <option value="brigada">Brigada Municipal</option>
            <option value="concessionaria">Concessionària</option>
        </#rp-app select>
        <div id="rol-tasks" class="rp-hidden">
            <!-- Tasques per rol es mostraran aquí -->
        </div>
        <#rp-app button type="#rp-app button" onclick="nextStep()">Continuar</#rp-app button>
    </div>

    <div class="rp-step-content" data-step="5">
        <h2>Pas 5: Resolució</h2>
        <p>Resolució de la reclamació:</p>
        <#rp-app select id="resolucio">
            <option value="favorable">Favorable</option>
            <option value="desfavorable">Desfavorable</option>
        </#rp-app select>
        <#rp-app textarea id="resum-reclamacio" placeholder="Resum de la reclamació i la resolució"></#rp-app textarea>
        <#rp-app button type="#rp-app button" onclick="generateResolution()">Enviar Resolució</#rp-app button>
    </div>

    <div class="rp-step-content" data-step="6">
        <h2>Pas 6: Tancament de la Reclamació</h2>
        <p id="final-resolution-text"></p>
        <#rp-app button type="#rp-app button" onclick="resetProcess()">Nova Reclamació</#rp-app button>
    </div>

    <!-- Botons de navegació -->
    <#rp-app button type="#rp-app button" onclick="prevStep()">Anterior</#rp-app button>
    <#rp-app button type="#rp-app button" onclick="nextStep()">Continuar</#rp-app button>

    <script>
        let currentStep = 1;
        let reclamantNom = "";
        let reclamantDNI = "";
        let reclamantDescripcio = "";
        let informesRebuts = [];

        function showStep(step) {
            document.querySelectorAll('#rp-app .rp-rp-progress-step').forEach(el => {
                el.classList.remove('active', 'completed');
            });
            document.querySelectorAll('#rp-app .rp-rp-step-content').forEach(el => {
                el.classList.remove('active');
            });

            document.querySelector(`#rp-app .rp-rp-progress-step[data-step="${step}"]`).classList.add('active');
            document.querySelector(`#rp-app .rp-rp-step-content[data-step="${step}"]`).classList.add('active');
            
            for (let i = 1; i < step; i++) {
                document.querySelector(`#rp-app .rp-rp-progress-step[data-step="${i}"]`).classList.add('completed');
            }

            currentStep = step;
        }

        function nextStep() {
            if (currentStep < 6) {
                showStep(currentStep + 1);
                if (currentStep === 3) {
                    updateRolsList();
                }
                if (currentStep === 4) {
                    updateInformesList();
                }
            }
        }

        function prevStep() {
            if (currentStep > 1) {
                showStep(currentStep - 1);
            }
        }

        function togglePersonaDocuments() {
            document.getElementById('persona-documents').classList.toggle('rp-hidden', !document.getElementById('persona').checked);
        }

        function toggleVehicleDocuments() {
            document.getElementById('vehicle-documents').classList.toggle('rp-hidden', !document.getElementById('vehicle').checked);
        }

        function toggleEdificiDocuments() {
            document.getElementById('edifici-documents').classList.toggle('rp-hidden', !document.getElementById('edifici').checked);
        }

        function toggleBeDocuments() {
            document.getElementById('be-documents').classList.toggle('rp-hidden', !document.getElementById('be').checked);
        }

        function updateRolsList() {
            const #rp-app selectedTypes = document.querySelectorAll('#rp-app input[type="checkbox"]:checked');
            const rolsList = document.getElementById('rols-list');
            rolsList.innerHTML = '';
            #rp-app selectedTypes.forEach(type => {
                let rols;
                switch (type.value) {
                    case 'persona':
                        rols = 'Policia';
                        break;
                    case 'vehicle':
                        rols = 'Policia, Tècnic de Vehicles';
                        break;
                    case 'edifici':
                        rols = 'Policia, Arquitecte, Brigada Municipal';
                        break;
                    case 'be':
                        rols = 'Policia, Concessionària, Brigada Municipal';
                        break;
                }
                rols.split(', ').forEach(rol => {
                    const li = document.createElement('li');
                    li.textContent = `${rol} (per a ${type.labels[0].innerText})`;
                    rolsList.appendChild(li);
                });
            });
        }

        function updateInformesList() {
            const #rp-app selectedTypes = document.querySelectorAll('#rp-app input[type="checkbox"]:checked');
            const informesList = document.getElementById('informes-list');
            informesList.innerHTML = '';
            #rp-app selectedTypes.forEach(type => {
                let informe;
                switch (type.value) {
                    case 'persona':
                        informe = 'Informe Policial';
                        break;
                    case 'vehicle':
                        informe = 'Informe Policial, Informe Tècnic del Vehicle';
                        break;
                    case 'edifici':
                        informe = 'Informe Policial, Informe Tècnic d\'Arquitecte, Informe de la Brigada Municipal';
                        break;
                    case 'be':
                        informe = 'Informe Policial, Informe de la Concessionària, Informe Tècnic, Informe de la Brigada Municipal';
                        break;
                }
                const div = document.createElement('div');
                div.innerHTML = `<#rp-app input type="checkbox" class="informe-check" id="${type.value}-informe" value="${type.value}">
                                <label for="${type.value}-informe">${informe} (per a ${type.labels[0].innerText})</label><br>`;
                informesList.appendChild(div);
            });
        }

        function showRoleTasks() {
            const roleTasks = document.getElementById('rol-tasks');
            const #rp-app selectedRole = document.getElementById('rol-#rp-app select').value;
            roleTasks.classList.add('rp-hidden');
            roleTasks.innerHTML = '';

            if (#rp-app selectedRole) {
                const tasks = document.createElement('div');
                switch (#rp-app selectedRole) {
                    case 'policia':
                        tasks.innerHTML = `
                            <h3>Tasques de Policia</h3>
                            <p>Detalls de l'incident (circumstàncies, lloc, hora, etc.)</p>
                            <p>Fotografia i altres evidències recollides</p>
                        `;
                        break;
                    case 'tecnic_vehicles':
                        tasks.innerHTML = `
                            <h3>Tasques de Tècnic de Vehicles</h3>
                            <p>Valoració dels danys al vehicle</p>
                            <p>Justificant de les reparacions necessàries (pressupost o factura)</p>
                        `;
                        break;
                    case 'arquitecte':
                        tasks.innerHTML = `
                            <h3>Tasques d'Arquitecte</h3>
                            <p>Identificació i valoració del bé afectat</p>
                            <p>Inspecció del lloc de l'incident (fotos, mesuraments, etc.)</p>
                        `;
                        break;
                    case 'brigada':
                        tasks.innerHTML = `
                            <h3>Tasques de Brigada Municipal</h3>
                            <p>Verificació i valoració de les reparacions fetes</p>
                            <p>Informació sobre material i dedicació</p>
                        `;
                        break;
                    case 'concessionaria':
                        tasks.innerHTML = `
                            <h3>Tasques de Concessionària</h3>
                            <p>Valoració dels danys al bé concessionat</p>
                            <p>Justificant de les reparacions necessàries (pressupost o factura)</p>
                        `;
                        break;
                    case 'tag':
                        tasks.innerHTML = `
                            <h3>Tasques del TAG</h3>
                            <p>Confirmar la recepció de tots els informes requerits</p>
                            <p>Obviar informes no rebuts en el termini indicat</p>
                        `;
                        break;
                }
                roleTasks.appendChild(tasks);
                roleTasks.classList.remove('rp-hidden');
            }
        }

        function generateResolution() {
            reclamantNom = document.getElementById('solicitant-nom').value;
            reclamantDNI = document.getElementById('solicitant-dni').value;
            reclamantDescripcio = document.getElementById('reclamacio-descripcio').value;

            const resolutionText = `
                <h3>Resolució</h3>
                <p><strong>Reclamant:</strong> ${reclamantNom} (DNI: ${reclamantDNI})</p>
                <p><strong>Descripció:</strong> ${reclamantDescripcio}</p>
                <p><strong>Informes rebuts:</strong> ${informesRebuts.join(', ')}</p>
                <p><strong>Resolució:</strong> ${document.getElementById('resolucio').value}</p>
                <p><strong>Resum:</strong> ${document.getElementById('resum-reclamacio').value}</p>
                <p>En cas de no estar conforme amb la resolució, podeu recórrer-la en el termini establert o acudir als tribunals.</p>
            `;
            document.getElementById('final-resolution-text').innerHTML = resolutionText;

            nextStep();
        }

        function resetProcess() {
            currentStep = 1;
            showStep(currentStep);
        }

        document.addEventListener('DOMContentLoaded', () => {
            showStep(currentStep);
        });
    </script>
</section>
</#rp-app>
</html>

:::
