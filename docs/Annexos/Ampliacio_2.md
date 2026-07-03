# Ampliació II: Liquidació Real de Músics i Balanç Anual de la Colla

## Context i Objectius Pedagògics

En l'ampliació I hem resolt un repartiment proporcional simple. No obstant això, en el dia a dia d'una agrupació musical, el repartiment és fix i depén de variables de formació, logística individual i col·laboracions externes. A més, com a entitat jurídica, la colla necessita un tancament econòmic global (ingressos reals vs. despeses estructurals i corrents) per a justificar la seua viabilitat o presentar els comptes a l'assemblea.

Com que continuem utilitzant **Odoo Community**, manquem d'un mòdul de nòmines (*Payroll*) o de comptabilitat analítica *Enterprise*. L'objectiu d'aquesta pràctica és utilitzar la potència del disseny de models relacionals de l'ORM d'Odoo per a estructurar un sistema de nòmina interna de la colla i generar un **model de Balanç Anual**.

## Nous Requisits Detallats del Sistema

La teua solució ha d'implementar i connectar els següents requisits de dades:

#### Tipologies d'Acte com a Model Independent (`agrupaciomusical.acte.tipus`)

El camp de selecció actual d'actes s'ha de transformar en un **nou model relacional** per a poder indexar la taula de preus de l'associació:

* Nom del tipus d'acte (ex: *Processó*, *Concert de Festes*, *Cercavila*, *Diana*).
* **Import fix del Músic de la colla:** L'import net en euros que guanya un músic per assistir a eixe tipus d'acte.
* **Import fix del Músic Extern (Llogat):** L'import fix que es paga als músics de reforç que es contracten fora de la colla.
* **Preu per Quilòmetre:** L'import en euros que la colla paga per cada quilòmetre recorregut (ex: $0.25€/km$).


#### El Model d'Acte (`agrupaciomusical.acte`)
 
Cada acte concret creat en el sistema ha d'especificar a més de la seua ubicació geogràfica els quilòmetres per arribar-hi:
* **Localitat:** Camp de text per a indicar on es fa l'actuació (ex: *Dénia*, *Alcoi*).
* **Quilòmetres:** Camp numèric que indica la distància total del desplaçament (anada i tornada) des del local de la colla fins a la localitat de l'acte.
 

#### Condicionants en el Músic (`agrupaciomusical.music`) i la participació

* **Músics en formació:** S'ha de controlar la data d'alta del músic a la colla. **Si el músic porta menys d'un any de trajectòria, el seu guany es reduirà automàticament a la meitat (50%)**, ja que es considera que encara està en període de formació.
* **Logística de vehicles propis (Dinàmica):** En la línia de participació de l'acte es podrà marcar si el músic aporta el seu vehicle. Si la casella està marcada, el sistema ha de calcular de manera dinàmica l'**Ingrés per quilometratge** de la següent manera:
   $$\text{Import Quilometratge} = \text{Quilòmetres de l'Acte} \times \text{Preu per Quilòmetre del Tipus d'Acte}$$
Aquest resultat conceptual es sumarà automàticament a la seua liquidació individual final de l'acte en estat *Acceptat*.
* **Tipus de Músic:** S'ha de poder marcar si un músic convocat és membre oficial de la colla o un *Reforç Extern llogat*.

#### El Model de Balanç Anual (`agrupaciomusical.balanc`)

Aquest nou model de l'aplicació centralitzarà els comptes generals de la colla de manera anual (filtrant per any actual):

1. **Ingressos Globals (Camps calculats i directes):**
- *Ingressos per Actes:* Sumatori de tot el que han pagat els contractistes (clients) pels actes d'eixe any.
- *Subvencions (Ajuntament/Diputació):* Camp numèric directe d'entrada.
- *Total Ingressos:* Camp calculat que sume totes les fonts anteriors.


2. **Despeses Globals (Camps calculats i directes):**
- *Despeses del Local:* Manteniment estructural introduït per formulari (Lloguer del local d'assaig, llum, aigua, assegurances).
- *Honoraris del Director:* Despesa mensual de la direcció musical de la colla.
- *Despeses de Material:* Compra de partitures, instruments comunitaris, reparacions o uniformes.
- *Total Liquidació de Músics:* Camp calculat que extreu de la base de dades la suma de **tot el que s'ha pagat als músics** (de la colla, en formació, externs llogats i quilometratges) en tots els actes de l'any.
- *Lloguer de Vehicles Externs:* Imports pagats per furgonetes de transport.
- *Total Despeses:* Camp calculat amb el sumatori de totes les despeses anteriors.


3. **Resultat de l'Exercici:** Camp calculat que determine el Benefici o Pèrdua anual de la colla (Total Ingressos - Total Despeses).

## Guia de Desenvolupament (Passos conceptuals)

#### Pas 1: Migració i Relació de la Tipologia

Crea el model `agrupaciomusical.acte.tipus` i utilitza una relació *Many2one* en el model d'Acte per a substituir l'antic camp *Selection*. D'aquesta manera, quan un responsable cree un acte i trie "Processó", l'acte sabrà de manera inherent quins són els caixets base gràcies a la relació.

#### Pas 2: Lògica de la Liquidació Individual (Python)

Al model de participacions (`agrupaciomusical.participacio`), el camp calculat de l'import a cobrar ha d'aplicar ara la següent jerarquia lògica en Python en avaluar cada línia d'un acte en estat 'Acceptat':

1. *És extern llogat?* $\rightarrow$ Aplica l'import d'extern del tipus d'acte.
2. *És de la colla?* $\rightarrow$ Revisa els dies o anys d'antiguitat del perfil del músic. Si fa menys de 365 dies que s'ha donat d'alta, aplica l'import base de la colla dividit per dos. Si porta més d'un any, aplica l'import complet.
3. *Aporta cotxe?* $\rightarrow$ Si la casella està marcada, calcula els quilòmetres de l'acte per l'import del quilòmetre, i el suma al seu import per l'acte.

#### Pas 3: Desenvolupament del Balanç de la Colla

Crea el model `agrupaciomusical.balanc`. Per a computar el *Total Liquidació de Músics* i els *Ingressos per Actes*, hauràs de fer ús del mètode `search` o `read_group` de l'ORM d'Odoo sobre els models d'acte i participació, filtrant els registres que pertanguen a les dates de l'any del balanç.
També hauràs de tindre en compte que cada músic de la colla ha de pagar una cuota anual que es descompta de la seua liquidació. També els músics novells paguen la meitat de la cuota.

#### Pas 4: Interfície d'Usuari i Menús

* Crea un nou menú i vista de llista/formulari per a gestionar els preus de les tipologies d'acte (només accessible per a la **Directiva**).
* Crea un menú a la barra superior anomenat **Tresoreria / Balanç Anual** que òbria el formulari del tancament d'any. Organitza la vista amb elements de tipus `<group>` per a separar clarament la columna d'ingressos de la de despeses, imitant un llibre de comptes clàssic.

#### Pas 5: Reinici i Prova de Cicle Complet

Reinicia el teu contenidor Docker, actualitza el mòdul i fes una prova de validació. 

Per a validar que tota la xarxa de dependències de dades funciona en viu, hauràs de documentar a la memòria el següent escenari de prova:

1. Un tipus d'acte "Moros i Cristians" configurat amb: Import colla = $50€$, Import extern = $45€$ i **Preu per Km = $0.30€$**.
2. Un acte concret anomenat "Entrada d'Alcoi", vinculat al tipus "Moros i Cristians", on s'indica: Localitat = *Alcoi* i **Quilòmetres = $90\text{ km}$** (totals d'anada i tornada).
3. Es convoquen i accepten 3 músics de la colla:
- **Músic A (Va amb el cotxe d'un company):** No aporta vehicle. La seua liquidació ha de marcar exactament **$50€$**.
- **Músic B (Aporta el seu cotxe privat):** Té la casella marcada. El sistema ha de calcular: $50€ + (90\text{ km} \times 0.30€) = 50€ + 27€ =$ **$77€$**.
- **Músic C (Aporta el seu cotxe privat però és novell):** Porta menys d'un any a la colla (cobra el 50% de l'import de l'acte ). El sistema ha de calcular: $25€ + (90\text{ km} \times 0.30€) = 25€ + 27€ =$ **$52€$**.
4. Es lloguen 1 músic més (extern):
- **Músic D (músic llogat):** No aporta vehicle. La seua liquidació ha de marcar exactament **$45€$**.


5. El Balanç Anual ha de recollir automàticament la suma total d'aquesta liquidació d'acte ($224€$) a la seua línia de despeses en llançar el tancament econòmic.

## Verificació i Entrega

1. **Lliura un document PDF** amb l'explicació de la solució que has desenvolupat. El document ha d'incloure de manera obligatòria les següents captures de pantalla comentades on s'aprecie el correcte funcionament del sistema en viu:
* **a) Taula de Tipologies d'Acte:** Captura de la nova vista de llista o formulari del model `agrupaciomusical.acte.tipus` on es vegen els diferents imports configurats (colla, extern) i l'import fix per quilòmetre estipulat (ex: $0.30€/\text{km}$).
* **b) Formulari de l'Acte Dinàmic:** Captura del formulari d'un acte concret (ex: "Entrada d'Alcoi") on es puga comprovar la localitat introduïda, els quilòmetres de distància totals i com l'acte està enllaçat a la seua tipologia.
* **c) Cas de Test en la Llista de participacions:** Una única captura de la graella de participacions de l'acte on es demostre que el teu mètode en Python calcula en viu els tres escenaris reals requerits:
1. Un músic veterà de la colla que cobra l'import sencer (sense cotxe).
2. Un músic novell (menys d'un any d'antiguitat) que veu el seu import reduït automàticament al 50%.
3. Un músic (veterà o novell) amb la casella de vehicle marcada, on es verifique que el sistema li ha sumat l'import correcte de quilometratge ($\text{km de l'acte} \times \text{preu km}$).
4. Un músic de reforç extern llogat amb el seu import fix independent.


* **d) El Panell del Balanç Anual:** Captura del formulari del model `agrupaciomusical.balanc` del present exercici, on es comprove el correcte funcionament dels camps calculats: el sumatori automatitzat dels ingressos per actes i de les despeses per liquidacions de músics, així com el resultat net final (Benefici/Pèrdua) de la colla després d'introduir manualment les subvencions i les despeses estructurals (local, director, etc.).


2. **Un fitxer ZIP** que continga l'estructura de fitxers completa del teu mòdul actualitzat (codi Python, fitxers XML de vistes i menús, i fitxers de seguretat si s'han modificat) per a la seua revisió i execució en el Docker del docent.