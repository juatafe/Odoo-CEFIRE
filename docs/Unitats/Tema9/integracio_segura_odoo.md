# 🔐 Integració segura amb tokens i middleware

Encara que Odoo permet autenticació mitjançant **claus d'API**, en
entorns professionals no és habitual que aplicacions externes es
connecten directament contra l'ERP.

En lloc d'això, s'utilitza una **API intermèdia** que actua com a capa
de seguretat i control.

------------------------------------------------------------------------

## Arquitectura recomanada

``` mermaid
flowchart LR
    C[Client extern] -->|Token JWT| A[API intermèdia]
    A -->|XML-RPC / JSON-RPC| O[Odoo]
    O --> DB[(PostgreSQL)]

    style A fill:#d5f5e3,stroke:#1e8449,stroke-width:2px
    style O fill:#d6eaf8,stroke:#2874a6,stroke-width:2px
```

------------------------------------------------------------------------

## Per què no connectar directament contra Odoo?

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

------------------------------------------------------------------------

## Flux típic amb autenticació per token

``` text
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

------------------------------------------------------------------------

## Comparativa: RPC vs REST

  -----------------------------------------------------------------------
  API RPC d'Odoo                      API REST típica
  ----------------------------------- -----------------------------------
  Un únic endpoint                    Diversos endpoints (`/clients`,
  (`/xmlrpc/2/object`)                `/orders`, etc.)

  Mètode genèric `execute_kw`         GET / POST / PUT / DELETE

  Model + mètode com a paràmetres     URL + verb HTTP

  No és REST nativa                   Arquitectura RESTful
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## Model de seguretat recomanat

En un entorn professional:

-   Crear un **usuari tècnic específic** en Odoo.
-   Assignar-li únicament els permisos necessaris.
-   Generar una **clau API exclusiva per a integracions**.
-   Implementar una API intermèdia amb validació de tokens.
-   Utilitzar sempre **HTTPS**.
-   Aplicar rotació periòdica de claus.

Aquesta arquitectura evita exposar directament el nucli de l'ERP i
millora la seguretat global del sistema.
