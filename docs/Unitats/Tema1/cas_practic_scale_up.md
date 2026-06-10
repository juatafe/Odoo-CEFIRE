# Cas Pràctic: Odoo Scale Up!
Per a comprendre el funcionament real d'un ERP, utilitzarem el joc de simulació **Scale Up!**, on gestionaràs una empresa de mobles anomenada "Mi Negocio S.A.". Utilitzarem Odoo 19 en la versió Enterprise. No anem a fer una reproducció literal del joc, sinó que seguirem el fil conductor de les primeres situacions plantejades per a entendre la lògica dels processos de negoci i la connexió entre les diferents aplicacions d'Odoo i deixem el tutorial del joc per a que el lector aprofundeixi en el seu moment.

## Flux de Treball Inicial: Compra i Venda
Hauràs de configurar Odoo per a completar el següent cicle operatiu:
1. **Crear productes**: Definir el catàleg de mobles.
2. **Compra**: Gestionar sol·licituds de cotització a proveïdors.
3. **Logística**: Rebre productes al magatzem (ús de codis de barres).
4. **Venda i Facturació**: Realitzar el cicle complet fins al registre del pagament i l'anàlisi de resultats.

## Objectiu
L'objectiu és aprendre a configurar els processos de negoci sense necessitat de programació inicial, entenent la lògica de l'usuari final abans d'entrar en el desenvolupament de mòduls. Scale Up! és una eina que permet simular l'ús d'Odoo en un entorn controlat, facilitant l'aprenentatge pràctic i la comprensió dels processos empresarials. A través d'aquest cas pràctic, els participants podran veure com les diferents aplicacions d'Odoo es connecten entre si per a gestionar una empresa de manera eficient.
## Passos a Seguir
1. **Instal·lació d'Odoo**: Entra a [www.odoo.com/es_ES/trial](https://www.odoo.com/es_ES/trial) i tria les aplicacions  ventes, comptabilitat, inventari i compres. 

::: {tip} 
**Selecció d'aplicacions**

Per al cas pràctic, assegura't de seleccionar les aplicacions «Vendes», «Comptabilitat», «Inventari» i «Compres» per cobrir el cicle complet compra–logística–venda–facturació.
:::

:::{image} /_static/assets/img/scaleup/triaraplicacions.png
:alt: Tria Aplicacions
:width: 35%
:align: center
:::

Caldrà identificar-se o crear un compte per a accedir a la plataforma. Un cop dins, podràs començar a configurar l'empresa i els processos de negoci.

:::{image} /_static/assets/img/scaleup/identificat.png
:alt: Crear Compte
:width: 85%
:align: center
:::     
El camp més important a configurar és el nom de l'empresa, que en aquest cas serà "edu-Mi Negocio". Odoo permet una empresa amb accés a l'ERP durant 24 mesos de manera gratuïta, amb totes les funcionalitats disponibles si s'utilitza la versió en línia amb el nom de l'empresa començant per "edu-". Això és ideal per a pràctiques i formació. En acabar el periode s'eliminara sense que pugues crear una copia de seguretat.

::: {danger} 
El nom de l'empresa ha de començar per «edu-» per obtindre l'accés educatiu. En finalitzar el període (24 mesos), l'instància s'eliminarà i NO es podrà descarregar una còpia de seguretat.
:::

En el moment de començar Odoo t'enviarà un correu d'activació que expira en 3 h. Si no es confirma, s'esborrarà l'empresa i caldrà crear-ne una de nova. Per a evitar aquest problema, és recomanable utilitzar un correu electrònic que es puga accedir fàcilment.

::: {caution} 
**Activació del compte**

Confirma el correu d'activació dins de les 3 hores. Si no ho fas, l'empresa s'esborrarà automàticament i hauràs de repetir el procés de creació.
:::

Una vegada creada l'empresa en accedir es vorà un panell de control on es poden configurar les diferents aplicacions i processos. A partir d'ací, es poden seguir els passos per a configurar l'empresa i començar a gestionar les operacions de compra, venda, inventari i comptabilitat.

:::{image} /_static/assets/img/scaleup/empresacreada.png
:alt: Panell de Control
:width: 85%
:align: center
:::

1. **Configuració Inicial**: Configura l'empresa "Mi Negocio S.A." a Odoo, incloent informació bàsica i paràmetres de l'empresa. Ves a a Ajustos → Opcions generals → Actualitzar informació o Gestionar Companyies.
   
:::{image} /_static/assets/img/scaleup/parametresempresa.png
:alt: Configuració Inicial
:width: 85%
:align: center
:::

En Ajustos també podem configurar l'idioma. 
::: {tip} 
**Idiomes**

Activa els idiomes necessaris (per exemple, «Català», «Español») i estableix la preferència d'idioma per usuari per millorar l'experiència d'ús.
:::
:::{image} /_static/assets/img/scaleup/idiomes.png
:alt: Configuració Idioma
:width: 85%
:align: center
::: 

1. **Creació de Productes**: Defineix els productes que oferirà l'empresa. 

El tutorial comença indicant que existeix un proveedor de mobles d'oficina (Muebles Madero) i el gerent de compres ens indica que  li agraden uns escritoris grans amb un preu de 1400€ però que si demanem mínim 10 unitats tenim un descompte del 10% i els podem vendre per 2200€. Anem a Compres → Productes → Productes i creem un nou producte anomenat «Escriptori Gran» amb el preu de venda de 2200€ i el preu de compra de 1400€. També podem configurar les unitats de mesura, les categories de producte i altres atributs rellevants. Recorda marcar el seguiment d'inventari si vols gestionar les existències d'aquest producte.
:::{image} /_static/assets/img/scaleup/escritorigran.png
:alt: Creació de Producte
:width: 85%
:align: center
:::

A la pestanya Compres, crearem el proveidor «Muebles Madero» i associem el producte «Escriptori Gran» amb el preu de compra de 1400€ i el descompte per volum del 10% per a comandes de 10 unitats o més. 

:::{image} /_static/assets/img/scaleup/proveedor.png
:alt: Configuració Proveïdor
:width: 85%
:align: center
:::

1. **Gestió de Compres**: Crea una sol·licitud de presupost (cotització) per a comprar 10 unitats d'«Escriptori Gran» a «Muebles Madero». Això es fa a Compres → Sol·licituds de Presupost → Nou. Selecciona el proveïdor, afegeix el producte i la quantitat, i guarda la sol·licitud.

:::{image} /_static/assets/img/scaleup/pressupost.png
:alt: Sol·licitud de Compra
:width: 85%
:align: center
::: 

Un vegada desada, pots convertir-la en una ordre de compra confirmant la comanda. 

:::{image} /_static/assets/img/scaleup/comanda.png
:alt: Ordre de Compra
:width: 85%     
:align: center
:::

El botó del camió et porta directament a la vista de recepció de mercaderies, on podràs gestionar l'arribada dels productes al magatzem.

::: {admonition} Clarificació
:class: important
El botó del camió no «obre Inventari», obri el moviment logístic que Inventari ha de processar.
:::
:::{image} /_static/assets/img/scaleup/comprobar.png
:alt: Recepció de Mercaderies
:width: 85%
:align: center
::: 
Cal validadar la recepció per a actualitzar l'inventari i registrar l'entrada dels productes al magatzem. Si tens configurat el seguiment d'inventari, podràs escanejar els codis de barres dels productes per a facilitar aquest procés. La integració d'odoo permet que aquesta acció actualitze automàticament les existències i ara a l'inventari apareixen 10 unitats «d'Escriptori Gran» disponibles per a la venda.

:::{image} /_static/assets/img/scaleup/inventari.png
:alt: Inventari Actualitzat
:width: 85%
:align: center
:::

**Gestió de Factures**: Després de rebre els productes, és important registrar la factura del proveïdor. Al mòdul de Comptabilitat es pot observar el tauler de control on es mostren les vendes, els bancs que es poden connectar, les compres i altres funcionalitats. 

:::{image} /_static/assets/img/scaleup/taulercompatibilitat.png
:alt: Comptabilitat
:width: 85%
:align: center
:::

Podem pujar la factura del proveidor manualment o utilitzar la funcionalitat de reconeixement de factures d'Odoo per a automatitzar aquest procés. Pots descarregar la factura de compra que has de pujar a Odoo: [Factura Compra Muebles Madero](https://github.com/juatafe/Odoo-CEFIRE/raw/main/docs/_static/assets/img/scaleup/factura_muebles_madero_INV2025_0001.pdf).

:::{image} /_static/assets/img/scaleup/factura.png
:alt: Factura Proveïdor
:width: 85%
:align: center
:::

Per a registrar la factura del proveïdor, anem a Comptabilitat → Proveïdors → Factures i creem una nova factura associada a la comanda de compra que acabem de confirmar. Això permetrà tenir un registre complet del procés de compra, des de la sol·licitud de pressupost fins al pagament de la factura.
:::{image} /_static/assets/img/scaleup/factura-escane.png
:alt: Registrar Factura Proveïdor
:width: 85%
:align: center
::: 

**Què ha passat en pujar la factura amb la IA d’Odoo**

En pujar el PDF de la factura del proveïdor *Muebles Madero*, Odoo ha utilitzat la seua funcionalitat d’intel·ligència artificial (OCR) per a reconéixer automàticament la informació del document. Aquest procés permet extraure dades com imports, dates, números de factura i impostos sense haver-les d’introduir manualment.

La IA ha reconegut correctament el número de factura (INV/2025/0001), la data de la factura, la base imposable de 10.000 €, l’IVA del 21% (2.100 €) i l’import total de 12.100 €. També ha assignat de manera correcta el compte comptable 600000 – Compres de mercaderies. Des del punt de vista numèric i fiscal, el reconeixement és correcte.

El problema apareix en la classificació del document, ja que Odoo ha creat el registre com un **Rebut** en lloc d’una **Factura de proveïdor**. Això no és un error de l’usuari, sinó una limitació del sistema d’IA. L’OCR pot reconéixer contingut, però no té criteri comptable per decidir amb total seguretat quin tipus de document s’ha d’utilitzar. En situacions de dubte, Odoo tendeix a marcar el document com a rebut.

Deixar el document com a rebut no és correcte dins del flux normal de compra d’Odoo. El procés adequat és: comanda de compra, recepció de mercaderia i, finalment, factura de proveïdor. Un rebut no queda ben integrat en aquest flux, no s’associa correctament amb l’ordre de compra i pot provocar incoherències en la gestió comptable i logística.

Per aquest motiu, és imprescindible que l’usuari revise el document creat per la IA i faça la correcció manual corresponent. En aquest cas, cal canviar el tipus de document de rebut a factura, seleccionar el proveïdor correcte (Muebles Madero) i validar la factura una vegada revisades les línies.

Aquest exemple mostra clarament que la intel·ligència artificial és una eina d’ajuda, però no substitueix el criteri de l’usuari. L’OCR automatitza la introducció de dades, però la decisió comptable final sempre ha de recaure en la persona que gestiona l’ERP. Aquest pas és fonamental per entendre el funcionament real d’Odoo abans d’entrar en automatitzacions o desenvolupament avançat.

En Auto-completar, selecciona la comanda P0001, així la factura quedarà vinculada a la compra. Revisa que no duplique linies i que els imports siguen correctes. Un cop revisada, valida la factura per a registrar-la oficialment al sistema. El banc del destinatari sols cal si després vols simular el pagament de la factura. En aquest cas, pots deixar-lo en blanc ja que no realitzarem aquesta acció en aquest moment. La referencia de pagament és un camp opcional que pots utilitzar per a associar la factura amb un número de referència de pagament, però no és necessari per a completar el registre de la factura al sistema.
:::{image} /_static/assets/img/scaleup/factura-avalidar.png
:alt: Factura Validada
:width: 85%
:align: center
:::

Una vegada comfirmada la factura, aquesta quedarà registrada al sistema i associada a la comanda de compra. Això permetrà tenir un control complet del procés de compra, des de la sol·licitud de pressupost fins al registre de la factura, facilitant la gestió comptable i logística de l'empresa.

:::{image} /_static/assets/img/scaleup/factura-validadapng.png
:alt: Factura Confirmada
:width: 85%
:align: center
:::


### El joc Scale Up! com a fil conductor

El joc **Scale Up!** és una simulació dissenyada per Odoo amb l’objectiu de mostrar el funcionament real d’un ERP mitjançant situacions empresarials habituals. L’usuari assumeix el rol de responsable d’una empresa fictícia, *Mi Negocio S.A.*, i pren decisions que afecten totes les àrees del sistema.

La finalitat del joc no és aprendre pantalles ni seguir instruccions mecàniques, sinó entendre la **lògica dels processos de negoci** i la connexió entre les diferents aplicacions d’Odoo. Cada acció té conseqüències directes en altres mòduls: una compra genera inventari, l’inventari permet vendre, la venda genera facturació i tot acaba reflectint-se en la comptabilitat.

En l’escenari inicial, *Compra i vende*, es treballa el cicle bàsic d’un ERP:
- Creació de productes
- Gestió de compres amb proveïdors
- Recepció de mercaderia
- Vendes a clients
- Facturació
- Registre de pagaments
- Conciliació bancària
- Anàlisi de resultats.

A mesura que el joc avança, s’introdueixen altres situacions reals com el punt de venda, el comerç electrònic, la venda de serveis, la fabricació, el control de qualitat i la gestió de projectes. Tot el contingut està pensat per mostrar el “per què” de cada pas i no només el “com”.

En aquest curs, **no es tracta de reproduir literalment el joc ni de copiar el seu manual**, sinó d’utilitzar-lo com a suport. El treball se centra a interpretar què està passant en cada moment, justificar les decisions preses, detectar errors habituals i entendre com actuaria una empresa real davant cada situació.
:::{image} /_static/assets/img/scaleup/elscaleup.png
:alt: Scale Up!
:width: 85%
:align: center
:::

Per continuar amb el joc complet i accedir a tots els escenaris disponibles, es pot descarregar el material oficial de Scale Up! des del següent enllaç:

[https://www.odoo.com/es_ES/r/Scale_Up_Download_ES](https://www.odoo.com/es_ES/r/Scale_Up_Download_ES)

A partir d’aquest punt, el joc servirà com a base per aprofundir en els processos empresarials, mentre que el criteri de l’usuari serà l’element clau abans de passar a configuracions avançades, automatitzacions o desenvolupament de mòduls.