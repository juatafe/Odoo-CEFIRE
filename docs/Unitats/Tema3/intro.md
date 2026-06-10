## Introducció

Aquest capítol fa el primer pas d’implantació d’Odoo en un entorn real. Partirem d’una instal·lació funcional per recórrer la interfície web, activar aplicacions, incorporar mòduls externs sense alterar els natius i establir la configuració essencial de l’empresa (identitat visual, correu i localització comptable). L’objectiu és entendre el flux inicial de treball, les bones pràctiques d’organització de mòduls i com deixar el sistema preparat per començar a operar.

Al llarg del capítol també veurem com el “Website Builder” facilita la creació i reconfiguració del lloc web, i quines opcions tenim per repetir l’assistent inicial de selecció de tema en entorns de pràctiques.



## Accés a la interfície web

Per accedir a Odoo, només cal obrir el navegador i escriure l’adreça del servidor on està instal·lat Odoo. Per exemple:

```{code-block} bash
http://IP_servidor:8069
```

Aquesta URL et portarà a la **pantalla inicial d’Odoo**, on podràs veure el formulari d’inici de sessió:

```{image} /_static/assets/img/T3_img1.png
:alt: Pantalla inicial d’Odoo
:width: 100%
:align: center
```
Cal iniciar sessió amb l’usuari administrador que has configurat durant la instal·lació d’Odoo. Aquest usuari té permisos per gestionar la plataforma i serà el punt de partida per afegir nous usuaris i configurar l’empresa.

:::{tip} 
**Accés i gestió de bases de dades**

A la pantalla inicial d’Odoo, només pots iniciar sessió en una base de dades ja creada.  
Per gestionar bases de dades (crear, duplicar o eliminar), cal accedir directament a la URL següent:

```{code-block} bash
http://localhost:8069/web/database/manager
```
```{image} /_static/assets/img/T3_manager.png
:alt: Gestió de les bases de dades
:width: 100%
:align: center
```

:::tip
Aquesta opció és útil si necessites crear, duplicar o eliminar bases de dades.
:::
:::

Per accedir a les aplicacions i configuracions, fes clic a la icona dels 9 quadrets (app switcher) situada a la part superior esquerra.
Des d’allí veuràs el menú principal amb tots els mòduls disponibles i podràs:

  - Accedir a la configuració de l’empresa **(Configuració → Usuaris i Empreses → Empreses)**.
  - Instal·lar mòduls nous des del menú **Aplicacions**.
  - Gestionar dades bàsiques i paràmetres generals.


```{image} /_static/assets/img/T3_mycompany.png
:alt: Administració d'Odoo
:width: 100%
:align: center
```

Aquesta interfície web permet controlar totes les funcionalitats d’Odoo de manera centralitzada i intuïtiva.

---


## Instal·lació de mòduls

### Mòduls propis
Odoo porta de sèrie aplicacions com **CRM, Vendes, Inventari, Facturació**.  
Aquests es poden activar directament des del menú **Aplicacions**.

```{image} /_static/assets/img/T3_img5.png
:alt: Llista de mòduls d’Odoo
:width: 100%
:align: center
```

### Mòduls externs
També podem afegir-ne de nous desenvolupats per la comunitat (OCA) o per empreses especialitzades.  

Bones pràctiques:  
- **No tocar els mòduls natius**: sempre que vulguem canviar alguna cosa, s’ha de fer mitjançant un mòdul nou que herete funcionalitat.  
- Guardar els mòduls externs en una carpeta separada, com `extra-addons` o `dev-addons`.  
- Afegir la ruta d’aquesta carpeta al fitxer `odoo.conf`.  

:::{tip} 
**Exemple amb Docker**

En `docker-compose.yml` podem muntar una carpeta local de mòduls:  

```{code-block} yaml
  web:
    image: odoo:19.0
    volumes:
      - ./extra-addons:/mnt/extra-addons
```

Així cada vegada que afegim o modifiquem un mòdul, es veurà reflectit dins del contenidor sense alterar els natius.  
:::

---

## Configuració bàsica de l’empresa

Una vegada tenim la base de dades, cal configurar els paràmetres generals de l’empresa.  

| **Element** | **Exemple** |
|-------------|-------------|
| Nom i logo  | “La Morralla” amb logotip corporatiu |
| Icona web (favicon) | Arxiu `.ico` per personalitzar la pestanya del navegador |
| Adreça i dades fiscals | Carrer, CIF, telèfon, correu electrònic |
| Servidor de correu | SMTP per enviar notificacions des d’Odoo |
| Pla comptable | Mòdul de localització `l10n_es` (PGC2008) descarregable des d’Aplicacions |

:::{danger} 
El mòdul de **localització del país** (en el nostre cas `l10n_es`) és imprescindible per tindre impostos i pla comptable correctes.  
Sense això, Odoo no estarà preparat per a facturar correctament.

Cal advertir que **el pla comptable d’una associació musical NO és** exactament igual que el d’una empresa, però s’assembla molt amb algunes adaptacions. A més pot canviar segon la legislació vigent. Aquesta anàlisi i adaptació requereix una complexitat que s’escapa del propòsit del curs.  
Per tant, treballarem amb el **pla comptable espanyol per a empreses** per simplificar els exemples.
:::

---
### Creació i reconfiguració del Website

Quan instal·lem el mòdul **Website (Lloc web)**, Odoo llança un **assistent inicial** que ens guia per a crear la web de l’empresa. Aquest *wizard* et permet:

- Seleccionar un **tema visual** (plantilla).  
- Triar colors i tipografia corporativa.  
- Generar una primera pàgina editable amb el **Website Builder**.

```{image} /_static/assets/img/T3_assistent.png
:alt: Assistent de selecció de tema en Website
:width: 100%
:align: center
```
*Pantalla de l’assistent inicial per a seleccionar un tema i crear la web.*

:::{tip} 
**Tornar a llançar el wizard**
Encara que l’assistent només apareix la primera vegada, hi ha diverses maneres de repetir-lo o simular-lo:


1. **Crear una web nova**  
   - A partir d’Odoo 16 es permet tenir més d’una web per base de dades.  
   - Menú: **Webs → Configuració → Webs → Crear**.  
   - En crear-ne una de nova, s’activa de nou l’assistent de selecció de tema.

2. **Reinstal·lar el mòdul Website**  
   - Només recomanat en entorns de prova.  
   - Desinstal·lar i tornar a instal·lar el mòdul fa que el wizard es mostre com si fóra la primera vegada.  
   - ⚠️ Aquesta acció elimina també les pàgines i configuracions prèvies de la web.
:::

:::{note} 
**Recomanació docent**

Per a practicar, és més segur **crear una web nova**, en lloc de reinstal·lar el mòdul.  
La reinstal·lació pot provocar pèrdua de dades i només és viable en una base de dades de proves.
:::

## Resum i pròxims passos
En aquest capítol hem vist com accedir a la interfície web d’Odoo, gestionar les bases de dades, activar mòduls i configurar els paràmetres bàsics de l’empresa. També hem explorat com funciona l’assistent de selecció de tema per a la web i com tornar a llançar-lo si cal.  

Ara convidria afegir el servidor de correu a l’entorn Docker d’Odoo. Com que en entorns de desenvolupament no volem fer enviaments reals, utilitzarem **MailHog** com a servidor SMTP de proves (Exercici pràctic 3).  Així podrem comprovar que Odoo genera els correus correctament i que MailHog els rep i els mostra en la seva interfície web, sense que cap missatge real s’envie fora del nostre entorn de desenvolupament.  A més, si vols automatitzar la instal·lació d’Odoo i la configuració de MailHog, pots realitzar l’exercici pràctic opcional Automatització de la instaŀlació d’Odoo amb Docker per agilitzar el procés en futurs projectes.