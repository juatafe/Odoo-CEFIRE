# Ampliació I: Gestió econòmica i liquidació d'actes

## Context i justificació tècnica (Odoo Community vs Enterprise)

Fins ara, la nostra aplicació de l'**Agrupació Musical** resol de manera brillant el control d'assistència i el triatge de músics per a cada esdeveniment. No obstant això, la junta directiva de la colla es troba amb un problema administratiu laboriós al final de cada actuació: **calcular quant ha de cobrar cada músic**.

En un entorn empresarial complet, podríem caure en la temptació d'utilitzar el mòdul de comptabilitat natiu d'Odoo. No obstant això, com que estem treballant amb la versió **Odoo Community**, trobem una limitació de llicència important: **la comptabilitat completa és una característica exclusiva de la versió de pagament (Odoo Enterprise)**. Com que la versió Community no disposa d'assentaments contables, definició de diaris analítics ni gestió avançada de despeses per defecte, la solució més eficient i econòmica per a l'associació és **desenvolupar un submòdul a mida en Python** per a gestionar la seua pròpia lògica de caixa.

La gestió econòmica d'aquesta colla de dolçaines es basa en les següents regles de negoci:

1. **Actes remunerats:** No totes les actuacions es cobren (per exemple, els assajos o les cercaviles de les trobales d'escoles en valencià tenen un preu de $0€$). Altres actes, com les processons, moros i cristians o correfocs, tenen un preu tancat que l'entitat contractant (client) paga a la colla segons de quin acte es tracte i el número de músics que volen que vagen.
2. **Despeses associades:** De l'import total que paga el client per l'acte, s'han de restar una sèrie de despeses logístiques reals abans de fer el repartiment. Aquestes despeses inclouen el quilometratge dels vehicles, el lloguer de furgonetes de transport de percussió en alguns casos o el cost dels arrastradors (normalment són xiquets que arrastren el carro dels timbals i bombo gran).
3. **El pot net i repartiment equitatiu:** Els diners restants (Preu de l'acte menys el total de despeses) es divideixen a parts iguals **únicament entre els músics que realment han assistit a tocar** (és a dir, aquells la participació dels quals estiga en estat *Acceptat*). Esta repartició proporcional i entre els participants és una simplificació de la realitat, que es fa per a tindre un primer contacte amb la gestió econòmica.

**L'objectiu d'aquesta pràctica** és ampliar els teus models en Python i dissenyar les vistes necessàries per a automatitzar aquest flux de caixa, de manera que en tancar un acte es genere automàticament la liquidació individual per a cada músic assistent, suplint la falta del mòdul de comptabilitat Enterprise.

En esta part del curs ja has de ser capaç de fer la teua propia solució, sense cap codi adicional, basant-te en tot el que has fet fins ara.


## Requisits detallats del sistema

Per a donar la pràctica per vàlida, la teua solució ha de complir de manera estricta els següents requisits de dades:

#### Ampliació del model d'acte (`agrupaciomusical.acte`)

* Un camp numèric per a indicar el **Preu de l'acte** pactat amb el client.
* Un mecanisme per a llistar **múltiples despeses** a l'acte. Cada despesa ha de contindre, com a mínim, un concepte o descripció (ex: *Lloguer de furgoneta*) i un import econòmic.
* Un camp calculat per al **Total de Despeses**, que sume automàticament totes les despeses introduïdes a l'acte.
* Un camp calculat per al **Benefici Net** de l'acte (Preu de l'acte menys Total de Despeses).
* Un camp calculat per al **Caché per Músic** (Benefici Net dividit entre el nombre total de músics assistents). Aquest camp ha de previndre errors matemàtics si l'acte encara no té músics assignats o acceptats.

#### Ampliació del model de participació (`agrupaciomusical.participacio`)

* Un camp calculat (o lligat al procés de liquidació) que mostre l'**Import a cobrar** pel músic en eixe acte concret.
* Si el músic finalment no hi assisteix (estat pendent, rebutjat o anul·lat), el seu import a cobrar ha de ser obligatòriament $0€$.

## Requisits avançats i opcionals (Gestió de clients i cobraments)

Per a aquells alumnes que vulguen anar més enllà i elevar la nota del projecte, la junta directiva ha demanat estendre el control econòmic cap als **clients (entitats contractants)** que paguen les actuacions (Ajuntaments, Comissions de Festes, Filaes de Moros i Cristians, particulars, etc.).

Com que a l'Odoo Community no disposem de l'ecosistema de Facturació i Comptabilitat *Enterprise* per a portar els comptes de clients (mòduls *Account Receivable*), s'ha d'implementar un control de deutes propi segons les següents condicions de l'associació:

1. **Tipologia de clients (`res.partner`):**
* S'ha de poder classificar si un client és **puntual** o **habitual**.
* **Clients puntuals:** Són aquells que contracten la colla per a un acte aïllat (ex: una cercavila). Se'ls exigeix pagar l'acte immediatament en acabar l'esdeveniment.
* **Clients habituals:** Són entitats de confiança o administracions públiques (ex: l'Ajuntament del poble, la colla de dimonis). A aquests clients se'ls permet acumular els imports dels actes i fer **1 o 2 pagaments globals a l'any** per a liquidar tot el que deuen.


2. **Control de l'estat de cobrament a l'acte:**
* Cada acte ha de tindre un camp d'estat per a saber si el preu de l'acte ja ha sigut **Cobrat** o està **Pendent de Cobrament**.


3. **Camps calculats de tresoreria al client:**
* El model de contactes (`res.partner`) ha de mostrar de manera dinàmica dos nous camps monetaris:
* **Total Contractat:** La suma del preu de *tots* els actes que eixe client ha contractat amb la colla.
* **Saldo Pendent (Deute):** La suma econòmica dels actes d'eixe client que estan en estat *Pendent de Cobrament*. Si el client és puntual i té algun acte pendent, el sistema podria llançar un avís visual.



## Guia de desenvolupament (Passos a seguir)

*Nota per a l'alumne:* L'arquitectura del codi és lliure. Pots decidir si crees nous fitxers o models, o si heretes i amplies l'estructura actual. A continuació es descriuen els passos lògics que has de resoldre:

#### Pas 1: Estructurar les despeses

Dissenya un model o estructura per a emmagatzemar les despeses de manera independent, per a poder afegir tantes despeses com faça falta a un sol acte (*Relació Many2one / One2many*). Pensa bé quins tipus de dades són els més correctes per als imports econòmics en Odoo.

#### Pas 2: Programar la lògica dels camps calculats

Al fitxer Python de l'acte, utilitza els decoradors de l'ORM d'Odoo (`@api.depends`) per a calcular de manera dinàmica els totals.

* *Pista de control d'errors:* Què passa si el benefici net dona negatiu o zero? Què passa si intentes dividir el benefici net entre zero músics acceptats? Assegura't que el teu codi Python controla aquestes situacions mitjançant condicions `if` per a evitar que el servidor d'Odoo s'enfonse en obrir la vista (errors de divisió per zero).

#### Pas 3: Connectar la liquidació amb el Músic

Troba la manera de fer que cada línia de participació sàpiga quin és el "Caché per Músic" de l'acte al qual està vinculada. El camp de la participació s'ha d'actualitzar automàticament al fer el tancament de l'acte, i tenim que impedir afegi una nova despesa a l'acte o modificar les participacions dels músics una vegada l'acte estiga ja tancant.
* *Pista de gestió real:* Què passa si l'equip directiu tanca amb massa pressa l'acte, sense haver introduït totes les despeses?


#### Pas 4: Actualitzar l'interfície gràfica (Vistes)

* **A la vista de l'Acte:** Organitza la interfície (per exemple, utilitzant una pestanya o *notebook* nova anomenada "Gestió Econòmica") on es puguen introduir el preu, la taula de despeses i es mostren de forma clara els camps calculats totals de l'acte.
* **A la vista de las Participacions (Llista i Formulari):** Afegeix el nou camp de l'import individual que guanya el músic perquè el responsable o la directiva puguen auditar els pagaments.

#### Pas 5: Reinici i prova de cicle complet

Reinicia el teu contenidor Docker, actualitza el mòdul i fes una prova de validació:

1. Crea un acte amb un preu de $500€$.
2. Afegeix dues despeses: *Kilometratge* ($75€$) i *Arrastradors* ($20€$). El Benefici Net hauria de marcar $405€$.
3. Convoca a 20 músics. Fes que 15 accepten, 2 rebutgen i 3 no contesten. Dels que accepten el responsable de l'acte anul.la l'acte a 3 d'ells, perquè l'acte s'ha contractat per a 12 músics. Comprova que el Caché per músic es recalcula a $33.75€$ i que només apareix l'import a cobrar a les fitxes dels 12 músics que finalment han assistit.

### Pistes de desenvolupament per als requisits avançats

*Nota per a l'alumne avantatjat:* Per a resoldre aquesta ampliació, hauràs de fer servir l'herència de models sobre `res.partner` i connectar-lo amb el teu model d'actes:

* **Pas A (Herència):** Estén el model de contactes d'Odoo (`res.partner`) per afegir un camp de selecció (*Selection*) per al tipus de client (Puntual/Habitual).
* **Pas B (Relació de Negoci):** Assegura't que l'acte (`agrupaciomusical.acte`) té un camp *Many2one* que apunte a `res.partner` per a saber quin client ha contractat l'actuació, així com el camp d'estat de cobrament (*Boolean* o *Selection*).
* **Pas C (Lògica de dominis en Python):** Per a calcular el *Saldo Pendent* del client, el teu mètode `@api.depends` en `res.partner` ha de fer un bucle o una cerca (`search`) en el model d'actes, filtrant només aquells registres vinculats a eixe contacte on el cobrament estiga com a fals o pendent.
* **Pas D (Vistes de Client):** Modifica la vista de formulari de contactes per a mostrar aquests camps de control financer. Un directiu de la colla ha de poder entrar a la fitxa de l'Ajuntament i veure instantàniament quants diners té retinguts i pendents de transferència.


## Verificació i entrega

1. Lliura un document pdf amb l'explicació de la solució que has desenvolupat i captures de pantalla on es puga apreciar:
a) El formulari de l'acte amb el desglossament de despeses i els resultats dels camps calculats funcionant en viu.
b) La llista d'assistència on es demostre que només els músics en estat 'Acceptat' tenen assignat el seu import de cobrament.
c) Si optes per lliurar l'ampliació opcional captura del panell del Client: On es demostre un client Habitual amb 3 actes assignats (2 cobrats i 1 pendent), verificant que el Saldo Pendent només suma l'import de l'acte que es deu.

2. Un zip con estiguen tots els fitxers per a la implementació del teu mòdul.