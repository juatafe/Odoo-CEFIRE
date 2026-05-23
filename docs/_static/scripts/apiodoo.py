# -*- coding: utf-8 -*-
"""
Mòdul d'interconnexió amb Odoo via XML-RPC.
Aquest script facilita les operacions CRUD (Create, Read, Update, Delete)
reutilitzant la sessió per a optimitzar el rendiment.
"""

import xmlrpc.client
import ssl
import sys
import yaml

# ------------------------------------------------------
# 1. GESTIÓ DE CONFIGURACIÓ
# ------------------------------------------------------

def read_app_props(env: str) -> dict:
    """
    Llegeix el fitxer YAML de configuració.
    
    Args:
        env (str): L'entorn a carregar ('development', 'production').
    Returns:
        dict: Diccionari amb les claus 'url', 'port', 'db', 'user', 'password'.
    """
    # sys.path[0] ens assegura que busquem el fitxer a la carpeta de l'script
    configFile = sys.path[0] + "/config.yml"
    
    with open(configFile, 'r', encoding='utf-8') as f:
        # safe_load evita l'execució de codi arbitrari dins del YAML
        configData = yaml.safe_load(f).get(env)
        
    return configData

# ------------------------------------------------------
# 2. CLIENTS DE CONNEXIÓ (PROXIES)
# ------------------------------------------------------

def get_client(props: dict, service: str):
    """
    Crea un servidor proxy per a un servei específic d'Odoo.
    
    Args:
        props (dict): Propietats de connexió.
        service (str): 'common' per login/versió o 'object' per a dades.
    """
    conn = props.get('connection')
    url = f"{conn['url']}:{conn['port']}/xmlrpc/2/{service}"
    
    # allow_none=True permet rebre valors nuls des d'Odoo
    # context=ssl._create_unverified_context() ignora certificats SSL no vàlids
    return xmlrpc.client.ServerProxy(
        url,
        allow_none=True,
        context=ssl._create_unverified_context()
    )

# ------------------------------------------------------
# 3. AUTENTICACIÓ I CONSULTES
# ------------------------------------------------------

def getuid(props: dict) -> int:
    """
    Realitza el procés de login.
    Retorna el User ID (uid) necessari per a totes les operacions posteriors.
    """
    conn = props.get('connection')
    common = get_client(props, 'common')
    
    # El mètode login retorna un enter (UID) si té èxit o False si falla
    return common.login(
        conn['db'],
        conn['user'],
        conn['password']
    )

def request_props(props: dict, uid: int, tablename: str, operation: str,
                  args: list = [], kwargs: dict = {}):
    """
    Funció mestra per executar qualsevol operació a Odoo (execute_kw).
    
    Args:
        uid (int): L'identificador d'usuari obtingut amb getuid().
        tablename (str): El model d'Odoo (ex: 'res.partner', 'sale.order').
        operation (str): El mètode (ex: 'search', 'read', 'create', 'write', 'unlink').
        args (list): Llista de filtres o IDs (sempre dins d'una llista).
        kwargs (dict): Paràmetres addicionals (camps, límits, ordres).
    """
    conn = props.get('connection')
    models = get_client(props, 'object')

    # Estructura obligatòria d'Odoo: (db, uid, password, model, mètode, arguments)
    return models.execute_kw(
        conn['db'],
        uid,
        conn['password'],
        tablename,
        operation,
        args,
        kwargs
    )

# ------------------------------------------------------
# 4. EXEMPLES D'OPERACIONS (CRUD)
# ------------------------------------------------------

def main_test():
    """Proves basades en les operacions d'A2Systems."""
    
    # Carreguem dades de l'entorn
    props = read_app_props("development")
    uid = getuid(props)
    
    if not uid:
        print("Error en l'autenticació!")
        return

    print(f"Connexió establerta. UID: {uid}")

    # --- EXEMPLE 1: SEARCH (Cercar IDs) ---
    # Busquem IDs de contactes que són persones (no empreses)
    person_ids = request_props(props, uid, 'res.partner', 'search', 
                             [[['is_company', '=', False]]], 
                             {'limit': 5})
    print(f"IDs de persones: {person_ids}")

    # --- EXEMPLE 2: READ (Llegir dades d'IDs coneguts) ---
    if person_ids:
        data = request_props(props, uid, 'res.partner', 'read', [person_ids], {'fields': ['name', 'email']})
        print(f"Dades llegides: {data}")

    # --- EXEMPLE 3: CREATE (Crear un nou registre) ---
    # (Descomenta per provar-ho)
    # new_id = request_props(props, uid, 'res.partner', 'create', [{'name': 'Nou Client de Prova'}])
    # print(f"Nou client creat amb ID: {new_id}")

if __name__ == "__main__":
    main_test()