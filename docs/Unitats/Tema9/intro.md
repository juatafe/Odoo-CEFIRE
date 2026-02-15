
## Introducció a la integració de sistemes d’informació

En l’actualitat, les organitzacions no utilitzen un únic sistema informàtic aïllat, sinó **un conjunt de sistemes interconnectats** que comparteixen dades i processos. Odoo incorpora plugins i eines per facilitar aquesta integració. Per exemple, podem instal·lar plugins que ens conecten bancs, botigues en línia, sistemes de facturació electrònica, etc. Però a més, Odoo disposa d’una **API** que permet la integració amb altres sistemes externs de manera personalitzada.

La **integració de sistemes d’informació** és el conjunt de tècniques i mecanismes que permeten:
- Intercanviar informació entre aplicacions,
- Coordinar processos,
- Evitar la duplicació de dades.

En aquest context, els **ERP** actuen com a **nucli central d’informació** de l’organització.



## Sistemes integrats vs sistemes aïllats
Els sistemes aïllats presenten diversos problemes que es resolen amb la integració mitjançant un ERP. A continuació es mostra una comparativa entre ambdós enfocaments:

| Sistemes aïllats | Sistemes integrats |
|------------------|-------------------|
| Dades duplicades | Base de dades comuna |
| Errors manuals | Automatització |
| Processos lents | Fluxos en temps real |
| Dependència humana | Comunicació sistema-sistema |


La duplicació de dades en sistemes aïllats pot generar inconsistències i errors. En canvi, un ERP integrat com Odoo centralitza la informació, permetent que diferents aplicacions accedeixin a les mateixes dades de manera controlada i segura.
```{mermaid}
flowchart LR
    A[Aplicacions aïllades] -->|Duplicació| B[Errors]
    C[ERP central] --> D[API]
    D --> E[Web]
    D --> F[App mòbil]
    D --> G[Altres sistemes]

    style C fill:#d6eaf8,stroke:#2874a6,stroke-width:2px
    style D fill:#aed6f1,stroke:#2874a6,stroke-width:2px
```



## Concepte d’API 

Una **API**(Application Programming Interface) és una interfície que permet que **un programa utilitze funcionalitats d’un altre programa** sense conéixer la seua implementació interna.

Dit d’una manera formal:

> "Una API defineix **com** es pot accedir a les dades i operacions d’un sistema."

En el cas d’Odoo, l’API permet consultar dades (clients, factures, productes…), crear o modificar registres, executar operacions del negoci sense utilitzar la interfície web. Açò facilita la integració amb altres sistemes (botigues en línia, facturació electrònica, etc.), però també pot suposar un risc de seguretat si no es gestiona adequadament. En aquest capíto treballarem directament amb l’API d’Odoo per comprendre el seu funcionament bàsic; més endavant veurem com protegir-ne l’accés mitjançant tokens i una API intermitja que actue com a capa de seguretat i control encara que no la desenvoluparem en aquest tema.




## Arquitectura d’Odoo i accés mitjançant API

Odoo utilitza una arquitectura **client-servidor** amb les següents capes:
- Base de dades (PostgreSQL),
- Capa ORM,
- Lògica de negoci (models),
- Interfície web,
- **API d’accés remot**.

```{mermaid}
flowchart TD
    DB[(PostgreSQL)]
    ORM[ORM Odoo]
    M[Models]
    W[Client Web]
    API[API XML-RPC / JSON-RPC]
    EXT[Sistemes externs]

    DB --> ORM --> M
    M --> W
    M --> API
    API --> EXT

    style API fill:#f9e79f,stroke:#b7950b,stroke-width:2px
```

L’API accedeix **directament als models**, igual que la interfície web, però sense renderitzar vistes.



## Tipus d’API disponibles en Odoo

Odoo proporciona diferents mecanismes d’accés directe remot, sent els més comuns **XML-RPC** i **JSON-RPC**. Tots dos permeten executar operacions sobre els models d’Odoo, però utilitzen formats de dades diferents.

### XML-RPC
L'acces amb **XML-RPC** és el mètode més tradicional i àmpliament suportat per interactuar amb Odoo. Característiques principals:
- Basada en crides a procediments remots.
- Estable i àmpliament utilitzada.
- Adequada per a scripts i automatització.

### JSON-RPC
El **JSON-RPC** és una alternativa més moderna que utilitza JSON per a la serialització de dades. Característiques principals:
- Basada en JSON.
- Variant moderna de XML-RPC.
- Més habitual en entorns web.

En aquest capítol es treballarà **XML-RPC**, per la seua simplicitat i compatibilitat.

## Integració segura amb tokens i middleware

Encara que Odoo permet autenticació mitjançant **claus d'API**, en
entorns professionals no és habitual que aplicacions externes es
connecten directament contra l'ERP.

En lloc d'això, s'utilitza una **API intermèdia** que actua com a capa
de seguretat i control.



### Arquitectura recomanada
En entorns professionals, es recomana utilitzar una API intermitja que gestione l'autenticació i les peticions cap a Odoo. Aquesta API pot generar **tokens JWT** per a cada client extern i aplicar validacions addicionals abans de cridar Odoo.

```{mermaid}
flowchart LR
    C[Client extern] -->|Token JWT| A[API intermèdia]
    A -->|XML-RPC / JSON-RPC| O[Odoo]
    O --> DB[(PostgreSQL)]

    style A fill:#d5f5e3,stroke:#1e8449,stroke-width:2px
    style O fill:#d6eaf8,stroke:#2874a6,stroke-width:2px
```



### Per què no connectar directament contra Odoo?

Si una aplicació externa es connecta directament a Odoo mitjançant
XML-RPC:

-   Necessita usuari i clau API.
-   Té accés complet segons els permisos assignats.
-   No es pot limitar fàcilment quines operacions pot fer.
-   No es pot aplicar control de peticions (*rate limit*).
-   Es complica el registre d'auditories externes.

En canvi, amb una API intermèdia pròpia es pot:

-   Generar **tokens temporals (JWT)**.
-   Limitar els endpoints exposats.
-   Aplicar validacions addicionals.
-   Registrar logs d'accés.
-   Canviar el backend sense afectar els clients.



### Flux típic amb autenticació per token
Si utilitzem una API intermèdia amb tokens, el flux típic seria:

```text
POST /login
→ retorna access_token

GET /partners
Authorization: Bearer <token>
```

Procés:

1.  El client envia credencials a la nostra API.
2.  La nostra API valida contra Odoo.
3.  Si l'autenticació és correcta, es genera un **token amb expiració**.
4.  El client utilitza aquest token en cada petició posterior.
5.  La nostra API verifica el token abans de cridar Odoo.



### Comparativa: RPC vs REST
La API d’Odoo és un sistema de **Remote Procedure Call (RPC)**, mentre que moltes APIs modernes segueixen l’estil **RESTful**. A continuació es mostra una comparativa entre ambdós enfocaments:
| Aspecte    | API RPC d'Odoo | API REST típica |
|------------|-----------------|-----------------|
| Endpoints  | Un únic endpoint (`/xmlrpc/2/object`) | Diversos endpoints (`/clients`, `/orders`, etc.) |
| Operacions | Mètode genèric `execute_kw` | Verbs HTTP: `GET`, `POST`, `PUT`, `DELETE` |
| Adreçament | Model + mètode com a paràmetres | URL + verb HTTP |
| Estil      | No és REST nativa (RPC) | Arquitectura RESTful |
| Format de dades | XML-RPC / JSON-RPC | JSON (habitual) |
| Especificació | Sense contracte estàndard | Sovint OpenAPI/Swagger |
| Autenticació | Usuari + clau API d’Odoo | Token Bearer / API Keys / OAuth2 |



### Model de seguretat recomanat en producció

En un entorn professional es recomana seguir les següents pràctiques per a una integració segura amb Odoo:

-   Crear un **usuari tècnic específic** en Odoo.
-   Assignar-li únicament els permisos necessaris.
-   Generar una **clau API exclusiva per a integracions**.
-   Implementar una API intermèdia amb validació de tokens.
-   Utilitzar sempre **HTTPS**.
-   Aplicar rotació periòdica de claus.

Aquesta arquitectura evita exposar directament el nucli de l'ERP i
millora la seguretat global del sistema.


## Autenticació i seguretat en l’accés per API en desevolupament

L’accés a l’API d’Odoo està protegit per mecanismes d’autenticació. Per motius de seguretat **no s’ha d’utilitzar la contrasenya real de l’usuari**, s’utilitzen **claus d’API**.

Les claus d’API:
- Identifiquen l’usuari,
- Es poden revocar,
- Limiten riscos en cas de filtració.

### Generació de clau API (pas a pas)
1. Inicia sessió i ves a "El meu perfil" (icona superior dreta).

::::{image} /_static/assets/img/Tema10/elmeuperfil.png
:alt: El meu perfil
:class: img-fluid
:height: 7cm
::::    

1. Obri la pestanya "Seguretat del compte" i entra a "Claus API".
   
::::{image} /_static/assets/img/Tema10/seguretat.png
:alt: Seguretat del compte
:class: img-fluid
::::

1. Clica "Nova clau API" i escriu una descripció clara (p. ex. "Connexió API").

::::{image} /_static/assets/img/Tema10/NomClau.png
:alt: Nova clau API
:class: img-fluid
::::

2. Confirma amb la teua contrasenya d’Odoo per crear-la.

::::{image} /_static/assets/img/Tema10/password.png
:alt: Confirma contrasenya
:class: img-fluid
::::

3. Guarda la clau generada en un gestor de secrets. No es pot recuperar més endavant.

::::{image} /_static/assets/img/Tema10/NovaClauCreada.png
:alt: Clau generada
:class: img-fluid
::::

4. Consulta, renova o elimina claus des de la mateixa secció.
Per motius de seguretat, només es mostra la clau un cop generada. Podràs eliminar-la i crear-ne una de nova si la perds.
::::{image} /_static/assets/img/Tema10/clausAPi.png
:alt: Gestió de claus
:class: img-fluid
::::


```{admonition} Bones pràctiques
:class: tip

- No compartisques la clau; revoca-la si es compromet.
- Si documentes a GitHub, evita pujar credencials al repositori; usa variables d’entorn.
- Limita permisos i rota claus periòdicament.
```



## Estructura d’un projecte de connexió amb l’API d’Odoo

Un projecte típic d’integració amb Odoo separa configuració, lògica de connexió i codi funcional. Això facilita manteniment i reutilització, així com canvi d’entorns (producció / desenvolupament).

Estructura exemple:
```text
Api-Odoo/
├── config.yml
├── main.py
├── img/
└── README.md
```

- `config.yml`: dades de connexió i entorns.
- `main.py`: lògica d’accés a l’API.
- `img/`: documentació gràfica del procés.
- `README.md`: instruccions d’ús.



### Configuració d’entorns i endpoints
Defineix credencials per a cada entorn en `config.yml` i apunta a l’endpoint de `common` (autenticació). El codi derivarà l’endpoint `object` per a operacions:

```yaml
production:
    connection:
        url: https://dominiodoo.es
        port: 443
        db: nom_bd
        user: usuari@example.com
        password: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  # clau API

development:
    connection:
        url: http://localhost
        port: 8069
        db: nom_bd
        user: usuari@example.com
        password: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  # clau API
```

Per canviar d’entorn en el codi, ajusta la variable `env` (p. ex. `env = "development"` o `env = "production"`).

### Obtenir el nom de la base de dades
Si no recordes el nom de la BD, consulta el gestor de BDs d’Odoo:

```html
https://www.dominiodoo.es/web/database/manager
```

```html
http://localhost:8069/web/database/manager
```
### Instal·lació i execució
Per executar el projecte, assegura’t de tenir Python 3.8+ i les llibreries `requests` i `pyyaml` instal·lades. Primer crearem un entorn virtual i instal·larem les dependències:

```bash
python3 -m venv api-odoo-venv
source api-odoo-venv/bin/activate  # Linux / MacOS
#api-odoo-venv\Scripts\activate     # Windows
pip install -r requirements.txt
python3 main.py
```
El fitxer `requirements.txt` conté:
```text
requests
pyyaml
```
<!-- 139f8ba338da03495e4ad768f10b8b27467ff449 -->



Per eixir de l’entorn virtual:
```bash
deactivate
```



## Operacions bàsiques amb l’API d’Odoo

Mitjançant l’API XML-RPC es poden realitzar les operacions principals del sistema:

- **Lectura** de registres (`search`, `read`)
- **Creació** de registres (`create`)
- **Modificació** de dades (`write`)
- **Eliminació** de registres (`unlink`)

Aquestes operacions actuen sobre els **mateixos models** que s’utilitzen al backend d’Odoo.

### Exemple pràctic amb XML-RPC (autenticació + lectura)
Exemple mínim per autenticar i llegir contactes (`res.partner`) utilitzant `search_read`:

:::{tip} 

Si vols provar ràpidament, pots descarregar un script d'exemple que realitza aquestes operacions bàsiques de connexió i consulta a l'API d'Odoo.

```{raw} latex
\href{https://juatafe.github.io/Odoo-CEFIRE/_static/scripts/main.py}{Descarrega main.py}
```
Descarrega'l, dona-li permisos d'execució i adapta'l al teu entorn.

:::


### Gestió d’errors comuns
Errors habituals i com abordar-los:
- "Autenticació fallida": revisa clau API, usuari i DB.
- Endpoint incorrecte: assegura `/xmlrpc/2/common` i derivació a `/object`.
- Permisos insuficients: comprova `check_access_rights` i rols.
- Problemes de xarxa/SSL: revisa ports (8069/443) i certificats.


## Resum del tema

En aquest tema hem vist:
- El concepte d’integració de sistemes d’informació,
- El paper de les APIs en els ERP,
- L’arquitectura d’Odoo i el seu accés remot,
- Els mecanismes d’autenticació segura,
- Operacions bàsiques mitjançant XML-RPC.

Odoo no és només una aplicació de gestió, sinó **una plataforma integrable** dins d’un ecosistema de sistemes d’informació.
