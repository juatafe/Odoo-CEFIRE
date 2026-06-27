# Odoo API XML-RPC amb HTTPS i Ngrok

Aquesta guia descriu com connectar-se a l'API d'Odoo de forma segura, utilitzant un túnel HTTPS per simular un entorn de producció.

```{admonition} Objectiu
:class: info

Exposar l’Odoo local (port 8069) a Internet via HTTPS (Ngrok) i consumir l’API XML-RPC amb un script Python que executa operacions de lectura bàsica.
```

## Requisits previs

- Odoo corrent en local (normalment port `8069`).
- `ngrok` instal·lat per exposar el servidor local.
- Entorn virtual de Python actiu amb `PyYAML` (XML-RPC està a la llibreria estàndard).
- **Novetat Odoo 19 (Obligatori)**: Una Clau d'API (`API Key`). Per seguretat, Odoo 19 ja no permet fer servir la contrasenya de l'usuari per l'API. Genera-la des del teu perfil d'Odoo (pestanya Seguretat > Claus d'API).


```bash
# Instal·lar ngrok (si no el tens)
# Veure https://ngrok.com/download

# Entorn Python
python3 -m venv .venv
source .venv/bin/activate
pip install pyyaml
```

```{admonition} Seguretat
:class: warning

No publiques claus ni credencials. Usa variables d’entorn o gestors de secrets. Revoca la clau API si es compromet.
```

## Configuració del túnel (HTTPS)

Per provar la connexió segura des de l'exterior, executa al terminal:

```bash
ngrok http 8069
```

Copia la URL generada (ex: `https://<subdomini>.ngrok-free.app`).

```{admonition} Nota
:class: tip

Ngrok crea un domini públic temporal amb certificat TLS vàlid. Ideal per a proves des de fora de la xarxa local.
```


## Estructura del projecte

Crea una carpeta anomenada `apiOdoo` i, dins, dos fitxers: `config.yml` i `apiodoo.py`.

## Fitxer de configuració (`config.yml`)

Configura les teues dades substituint els valors d'exemple. En el camp `password`, recorda enganxar la teua **API Key** generada:

```yaml
production:
  connection:
    url: "https://vostra-url.ngrok-free.app"
    port: 443
    db: "el_teu_nom_de_bd"
    user: "usuari@correu.com"
    password: "API KEY (no la contrasenya real)"
    verify_ssl: true
```

Punts clau:
- En HTTPS (`443`), no cal afegir el port a la URL; l’script construirà l’endpoint XML-RPC.
- `verify_ssl: true` utilitza verificació de certificat.
- La `password` ha de ser la clau API (no la contrasenya real).

## Operacions bàsiques (CRUD)
En aquesta pràctica, en lloc d'utilitzar models genèrics com res.partner, s'utilitzaran models del projecte propi per a reforçar l'aprenentatge contextualitzat.

### Lectura (`search_read`)
Serveix per buscar registres i obtenir els seus camps en una sola crida.

- Arguments: `[[filtres]]`, `{fields, limit, order}`.

### Escriptura (`write`)
Actualitza registres existents.

- Arguments: `[[llista_de_ids], {valors_a_canviar}]`.
- Retorna: `True` si s'ha fet correctament.

### Creació (`create`)
Crea un nou registre.

- Arguments: `[{valors}]`.
- Retorna: l’`ID` del nou registre.

```{admonition} Models comuns
:class: tip

`res.partner` (contactes), `sale.order` (comandes), `product.product` (productes), `account.move` (factures).
```

## Codi de la pràctica (main.py)

L’script es guardarà a `apiOdoo/main.py` i utilitza el `config.yml` d’eixa carpeta.

```python
# -*- coding: utf-8 -*-
import xmlrpc.client
import ssl
import sys
import yaml

def read_app_props(env: str) -> dict:
    """Llegeix la configuració des del YAML."""
    try:
        configFile = sys.path[0] + "/config.yml"
        with open(configFile, 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)
            return config.get(env)
    except Exception as e:
        print(f"Error llegint config.yml: {e}")
        return None

def get_client(props: dict, service: str):
    """Configura el client per a HTTP o HTTPS (ngrok)."""
    conn = props.get('connection')
    base_url = conn['url']
    port = conn['port']
    
    # Si és port 443 (HTTPS estàndard), sovint no cal posar el port a la URL
    if port == 443:
        url = f"{base_url}/xmlrpc/2/{service}"
    else:
        url = f"{base_url}:{port}/xmlrpc/2/{service}"
    
    # Configuració del context SSL
    if conn.get('verify_ssl', True):
        # Ngrok fa servir certificats vàlids, així que això funcionarà
        context = ssl.create_default_context()
    else:
        context = ssl._create_unverified_context()
    return xmlrpc.client.ServerProxy(url, allow_none=True, context=context)

def main_test():
    # Provem l'entorn de producció creat amb ngrok
    env = "production" 
    props = read_app_props(env)
    
    if not props:
        print("Configuració no trobada.")
        return
    print(f"--- Connectant via HTTPS a: {props['connection']['url']} ---")

    try:
        # 1. Autenticació
        common = get_client(props, 'common')
        uid = common.login(
            props['connection']['db'],
            props['connection']['user'],
            props['connection']['password']
        )
        if not uid:
            print("Error d'autenticació: Revisa usuari, contrasenya o nom de la BD.")
            return
        print(f"Autenticat amb èxit! UID: {uid}")

        # 2. Operació de lectura (Exemple)
        models = get_client(props, 'object')
        version = common.version()
        print(f"Versió d'Odoo: {version.get('server_version')}")

        # Busquem els últims 5 actes creats
        acte_ids = models.execute_kw(
            props['connection']['db'], uid, props['connection']['password'],
            'agrupaciomusical.acte', 'search_read', [[]],
            {'fields': ['name'], 'limit': 5, 'order': 'id desc'}
        )       
        print("Últims registres:")
        for a in acte_ids:
            print(f"- {a['name']}")

    except Exception as e:
        print(f"Error de connexió: {e}")

if __name__ == "__main__":
    main_test()
```

## Verificació de resultats

Quan s'executa correctament, el terminal hauria de mostrar:

- Confirmació del `UID`.
- La llista d'actes obtinguda de la base de dades.
- El missatge d'actualització de l'últim registre.

```bash
# Executar des de la carpeta apiOdoo
cd apiOdoo
python3 main.py
```

```{admonition} Possibles problemes
:class: warning

- Autenticació fallida: revisa clau API, usuari i nom de BD.
- Endpoint incorrecte: comprova que la URL d’Ngrok és HTTPS i activa.
- Permisos insuficients: verifica rols i `check_access_rights`.
- Xarxa/SSL: si hi ha errors de certificat, prova amb `verify_ssl: false` només en proves.
```

