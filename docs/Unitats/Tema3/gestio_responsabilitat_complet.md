# Gestió de Responsabilitat Patrimonial

Aquest fitxer conté la versió incrustada de l'aplicació completa.

::{raw} html
<!DOCTYPE html>
<html lang="ca">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gestió de Responsabilitat Patrimonial</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f4f4;
            margin: 0;
            padding: 20px;
            text-align: center;
        }
        h1 {
            color: #333;
        }
        .progressbar {
            display: flex;
            justify-content: space-between;
            list-style: none;
            padding: 0;
            margin-bottom: 20px;
            counter-reset: step;
        }
        .progress-step {
            flex-grow: 1;
            position: relative;
            text-align: center;
            cursor: pointer;
        }
        .progress-step:before {
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
        .progress-step:after {
            content: '';
            position: absolute;
            width: 100%;
            height: 2px;
            background-color: #ccc;
            top: 14px;
            left: -50%;
            z-index: -1;
        }
        .progress-step:first-child:after {
            content: none;
        }
        .progress-step.active:before, .progress-step.completed:before {
            background-color: #007bff;
            border-color: #007bff;
            color: white;
        }
        .progress-step.completed:after {
            background-color: #007bff;
        }
        .step-content {
            display: none;
            padding: 20px;
            margin-top: 20px;
            background-color: white;
            border: 1px solid #ccc;
            border-radius: 5px;
        }
        .step-content.active {
            display: block;
        }
        button {
            padding: 10px 20px;
            margin: 10px;
            background-color: #007bff;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
        }
        button:hover {
            background-color: #0056b3;
        }
        input, select, textarea {
            width: 100%;
            padding: 8px;
            margin-top: 5px;
            margin-bottom: 10px;
            border: 1px solid #ccc;
            border-radius: 5px;
        }
        .hidden {
            display: none;
        }
        .type-damage-container {
            display: flex;
            justify-content: space-around;
            flex-wrap: wrap;
            margin-top: 10px;
        }
        .type-damage-container div {
            flex: 1;
            min-width: 150px;
            margin: 10px;
        }
        .damage-info {
            text-align: left;
        }
        .checkbox-container {
            display: flex;
            justify-content: space-around;
            flex-wrap: wrap;
        }
    </style>
</head>
<body>
    <h1>Gestió de Responsabilitat Patrimonial</h1>
    <ul class="progressbar">
        <li class="progress-step active" data-step="1">Inici</li>
        <li class="progress-step" data-step="2">Revisió</li>
        <li class="progress-step" data-step="3">Enviament</li>
        <li class="progress-step" data-step="4">Revisió Informes</li>
        <li class="progress-step" data-step="5">Resolució</li>
        <li class="progress-step" data-step="6">Tancament</li>
    </ul>

    <!-- Continguts dels passos -->
    <div class="step-content active" data-step="1">
        <h2>Pas 1: Iniciar Reclamació</h2>
        <input type="text" id="solicitant-nom" placeholder="Nom del Sol·licitant" required>
        <input type="text" id="solicitant-dni" placeholder="DNI" required>
        <textarea id="reclamacio-descripcio" placeholder="Descripció de la Reclamació" required></textarea>
        <p>Seleccioneu el tipus de danys:</p>
        <div class="type-damage-container">
            <div>
                <input type="checkbox" id="persona" value="persona" onchange="togglePersonaDocuments()">
                <label for="persona">Danys a Persona</label>
                <div id="persona-documents" class="hidden damage-info">
                    <p>Aporteu els següents documents:</p>
                    <input type="file" id="informe_medico" required>
                    <label for="informe_medico">Informe Mèdic</label><br>
                    <input type="file" id="justificant_despeses" required>
                    <label for="justificant_despeses">Justificant de Despeses Mèdiques</label><br>
                </div>
            </div>
            <div>
                <input type="checkbox" id="vehicle" value="vehicle" onchange="toggleVehicleDocuments()">
                <label for="vehicle">Danys a Vehicle</label>
                <div id="vehicle-documents" class="hidden damage-info">
                    <p>Aporteu la següent informació:</p>
                    <label for="vehicle_type">Tipus de Vehicle:</label>
                    <input type="text" id="vehicle_type" required><br>
                    <label for="vehicle_damage">Descripció dels Danys:</label>
                    <textarea id="vehicle_damage" required></textarea><br>
                    <label for="incident_location">Lloc de l'Incident:</label>
                    <input type="text" id="incident_location" required><br>
                    <label for="incident_time">Hora de l'Incident:</label>
                    <input type="time" id="incident_time" required><br>
                </div>
            </div>
            <div>
                <input type="checkbox" id="edifici" value="edifici" onchange="toggleEdificiDocuments()">
                <label for="edifici">Danys a Edifici Particular</label>
                <div id="edifici-documents" class="hidden damage-info">
                    <p>Aporteu la següent informació:</p>
                    <label for="building_damage">Descripció dels Danys:</label>
                    <textarea id="building_damage" required></textarea><br>
                    <label for="building_location">Lloc de l'Incident:</label>
                    <input type="text" id="building_location" required><br>
                    <label for="building_photos">Fotos del Dany:</label>
                    <input type="file" id="building_photos" accept="image/*" multiple required><br>
                </div>
            </div>
            <div>
                <input type="checkbox" id="be" value="be" onchange="toggleBeDocuments()">
                <label for="be">Danys a Bé Concessionat</label>
                <div id="be-documents" class="hidden damage-info">
                    <p>Aporteu la següent informació:</p>
                    <label for="concession_damage">Descripció dels Danys:</label>
                    <textarea id="concession_damage" required></textarea><br>
                    <label for="concession_location">Lloc de l'Incident:</label>
                    <input type="text" id="concession_location" required><br>
                    <label for="concession_photos">Fotos del Dany:</label>
                    <input type="file" id="concession_photos" accept="image/*" multiple required><br>
                </div>
            </div>
        </div>
        <button type="button" onclick="nextStep()">Continuar</button>
    </div>

    <div class="step-content" data-step="2">
        <h2>Pas 2: Revisió del TAG</h2>
        <p>Aquesta reclamació requereix diversos informes. Si us plau, confirmeu que la documentació està completa:</p>
        <div class="checkbox-container">
            <div>
                <input type="checkbox" id="doc_persona" class="tag-check" data-doc="persona">
                <label for="doc_persona">Documentació Danys a Persona Completa</label><br>
            </div>
            <div>
                <input type="checkbox" id="doc_vehicle" class="tag-check" data-doc="vehicle">
                <label for="doc_vehicle">Documentació Danys a Vehicle Completa</label><br>
            </div>
            <div>
                <input type="checkbox" id="doc_edifici" class="tag-check" data-doc="edifici">
                <label for="doc_edifici">Documentació Danys a Edifici Completa</label><br>
            </div>
            <div>
                <input type="checkbox" id="doc_be" class="tag-check" data-doc="be">
                <label for="doc_be">Documentació Danys a Bé Concessionat Completa</label><br>
            </div>
        </div>
        <button type="button" onclick="nextStep()">Continuar</button>
    </div>

    <div class="step-content" data-step="3">
        <h2>Pas 3: Enviament als Rols</h2>
        <p>La reclamació s'ha enviat als següents rols per a completar els informes necessaris:</p>
        <ul id="rols-list">
            <!-- Els rols es mostraran aquí dinàmicament -->
        </ul>
        <button type="button" onclick="nextStep()">Continuar</button>
    </div>

    <div class="step-content" data-step="4">
        <h2>Pas 4: Recepció dels Informes</h2>
        <p>Seleccioneu el vostre rol per veure les tasques assignades:</p>
        <select id="rol-select" onchange="showRoleTasks()">
            <option value="">Seleccioneu un rol</option>
            <option value="tag">TAG</option>
            <option value="policia">Policia</option>
            <option value="tecnic_vehicles">Tècnic de Vehicles</option>
            <option value="arquitecte">Arquitecte</option>
            <option value="brigada">Brigada Municipal</option>
            <option value="concessionaria">Concessionària</option>
        </select>
        <div id="rol-tasks" class="hidden">
            <!-- Tasques per rol es mostraran aquí -->
        </div>
        <button type="button" onclick="nextStep()">Continuar</button>
    </div>

    <div class="step-content" data-step="5">
        <h2>Pas 5: Resolució</h2>
        <p>Resolució de la reclamació:</p>
        <select id="resolucio">
            <option value="favorable">Favorable</option>
            <option value="desfavorable">Desfavorable</option>
        </select>
        <textarea id="resum-reclamacio" placeholder="Resum de la reclamació i la resolució"></textarea>
        <button type="button" onclick="generateResolution()">Enviar Resolució</button>
    </div>

    <div class="step-content" data-step="6">
        <h2>Pas 6: Tancament de la Reclamació</h2>
        <p id="final-resolution-text"></p>
        <button type="button" onclick="resetProcess()">Nova Reclamació</button>
    </div>

    <!-- Botons de navegació -->
    <button type="button" onclick="prevStep()">Anterior</button>
    <button type="button" onclick="nextStep()">Continuar</button>

    <script>
        let currentStep = 1;
        let reclamantNom = "";
        let reclamantDNI = "";
        let reclamantDescripcio = "";
        let informesRebuts = [];

        function showStep(step) {
            document.querySelectorAll('.progress-step').forEach(el => {
                el.classList.remove('active', 'completed');
            });
            document.querySelectorAll('.step-content').forEach(el => {
                el.classList.remove('active');
            });

            document.querySelector(`.progress-step[data-step="${step}"]`).classList.add('active');
            document.querySelector(`.step-content[data-step="${step}"]`).classList.add('active');
            
            for (let i = 1; i < step; i++) {
                document.querySelector(`.progress-step[data-step="${i}"]`).classList.add('completed');
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
            document.getElementById('persona-documents').classList.toggle('hidden', !document.getElementById('persona').checked);
        }

        function toggleVehicleDocuments() {
            document.getElementById('vehicle-documents').classList.toggle('hidden', !document.getElementById('vehicle').checked);
        }

        function toggleEdificiDocuments() {
            document.getElementById('edifici-documents').classList.toggle('hidden', !document.getElementById('edifici').checked);
        }

        function toggleBeDocuments() {
            document.getElementById('be-documents').classList.toggle('hidden', !document.getElementById('be').checked);
        }

        function updateRolsList() {
            const selectedTypes = document.querySelectorAll('input[type="checkbox"]:checked');
            const rolsList = document.getElementById('rols-list');
            rolsList.innerHTML = '';
            selectedTypes.forEach(type => {
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
            const selectedTypes = document.querySelectorAll('input[type="checkbox"]:checked');
            const informesList = document.getElementById('informes-list');
            informesList.innerHTML = '';
            selectedTypes.forEach(type => {
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
                div.innerHTML = `<input type="checkbox" class="informe-check" id="${type.value}-informe" value="${type.value}">
                                <label for="${type.value}-informe">${informe} (per a ${type.labels[0].innerText})</label><br>`;
                informesList.appendChild(div);
            });
        }

        function showRoleTasks() {
            const roleTasks = document.getElementById('rol-tasks');
            const selectedRole = document.getElementById('rol-select').value;
            roleTasks.classList.add('hidden');
            roleTasks.innerHTML = '';

            if (selectedRole) {
                const tasks = document.createElement('div');
                switch (selectedRole) {
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
                roleTasks.classList.remove('hidden');
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
</body>
</html>

:::
