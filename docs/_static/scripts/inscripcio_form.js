/** @odoo-module **/

import publicWidget from 'web.public.widget';

publicWidget.registry.InscripcioForm = publicWidget.Widget.extend({
    // El selector diu en quina part de la web s'ha d'activar el JS
    selector: '.container:has(#data_naixement)', 

    // Els esdeveniments: quan canvien la data, cridem a aplicarEdat
    events: {
        'change #data_naixement': '_onDataChange',
    },

    /**
     * S'executa quan el widget es carrega en la pàgina
     */
    start: function () {
        this._super.apply(this, arguments);
        // Cridem a la funció per si la pàgina ja ve amb dades (com dius tu, error de DNI)
        this._aplicarEdat();
    },

    _onDataChange: function () {
        this._aplicarEdat();
    },

    _aplicarEdat: function () {
        const dataInput = this.$('#data_naixement')[0];
        const blocTutor = this.$('#bloc_tutor')[0];
        const blocContacte = this.$('#bloc_contacte')[0];

        if (!dataInput || !dataInput.value || !blocTutor || !blocContacte) return;

        // --- LA TEUA LÒGICA D'EDAT ---
        const dataNaix = new Date(dataInput.value);
        if (isNaN(dataNaix)) return;

        const hui = new Date();
        let edat = hui.getFullYear() - dataNaix.getFullYear();
        const m = hui.getMonth() - dataNaix.getMonth();

        if (m < 0 || (m === 0 && hui.getDate() < dataNaix.getDate())) {
            edat--;
        }

        // --- GESTIÓ DE BLOCS I INPUTS ---
        const tutorInputs = blocTutor.querySelectorAll("input");
        const contacteInputs = blocContacte.querySelectorAll("input");

        if (edat < 18) {
            blocTutor.style.display = "block";
            blocContacte.style.display = "none";
            tutorInputs.forEach(i => i.required = true);
            contacteInputs.forEach(i => i.required = false);
        } else {
            blocTutor.style.display = "none";
            blocContacte.style.display = "block";
            tutorInputs.forEach(i => i.required = false);
            contacteInputs.forEach(i => i.required = true);
        }
    }
});


/*        document.addEventListener("DOMContentLoaded", function () {

            const dataInput = document.getElementById("data_naixement");
            const blocTutor = document.getElementById("bloc_tutor");
            const blocContacte = document.getElementById("bloc_contacte");

            const tutorInputs = blocTutor.querySelectorAll("input");
            const contacteInputs = blocContacte.querySelectorAll("input");

            function aplicarEdat() {
                if (!dataInput.value) return;

                const dataNaix = new Date(dataInput.value);
                if (isNaN(dataNaix)) return;

                const hui = new Date();
                let edat = hui.getFullYear() - dataNaix.getFullYear();
                const m = hui.getMonth() - dataNaix.getMonth();

                if (m < 0 || (m === 0 && hui.getDate() < dataNaix.getDate())) {
                    edat--;
                }

                if (edat < 18) {
                    blocTutor.style.display = "block";
                    blocContacte.style.display = "none";

                    tutorInputs.forEach(i => i.required = true);
                    contacteInputs.forEach(i => i.required = false);
                } else {
                    blocTutor.style.display = "none";
                    blocContacte.style.display = "block";

                    tutorInputs.forEach(i => i.required = false);
                    contacteInputs.forEach(i => i.required = true);
                }
            }

            // 🔹 quan canvia la data
            dataInput.addEventListener("change", aplicarEdat);

            // 🔹 quan la pàgina ja ve carregada (error DNI, etc.)
            aplicarEdat();
        }); */