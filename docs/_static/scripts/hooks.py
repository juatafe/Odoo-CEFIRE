# Importem l'API d'Odoo i la constant SUPERUSER_ID per executar accions com a superusuari
from odoo import api, SUPERUSER_ID

# Llista dels logins dels usuaris de prova que gestiona aquest mòdul
TEST_USERS = ['directiva_test', 'entrenadora_test', 'patinadora_test']

# Diccionari que mapeja cada login amb la referència XML del seu partner (res.partner) de prova
TEST_USER_PARTNERS = {
    'directiva_test': 'patinatge_inscripcio.partner_directiva_test',
    'entrenadora_test': 'patinatge_inscripcio.partner_entrenadora_test',
    'patinadora_test': 'patinatge_inscripcio.partner_patinadora_test',
}

# Referència única de la inscripció de prova de la patinadora
TEST_PATINADORA_REF = 'TEST-PAT-001'


# Hook que s'executa després d'instal·lar o actualitzar el mòdul (post_init_hook)
def create_test_users(cr, registry):
    # Creem un entorn Odoo amb permisos de superusuari
    env = api.Environment(cr, SUPERUSER_ID, {})

    # Obtenim els grups funcionals definits al mòdul
    group_dir = env.ref('patinatge_inscripcio.group_patinatge_directiva')
    group_ent = env.ref('patinatge_inscripcio.group_patinatge_entrenadora')
    group_pat = env.ref('patinatge_inscripcio.group_patinatge_patinadora')
    # Obtenim els grups estàndard d'Odoo per al tipus d'usuari
    group_internal = env.ref('base.group_user')   # usuari intern (empleat)
    group_portal = env.ref('base.group_portal')   # usuari portal (accés limitat)

    # Afegim el grup Directiva a l'usuari administrador (sense treure'n cap altre)
    admin = env.ref('base.user_admin')
    admin.write({'groups_id': [(4, group_dir.id)]})

    # Definim els usuaris de prova: (login, nom mostrat, grup funcional, tipus d'accés)
    users_to_fix = [
        # login, name, grup funcional, tipus usuari
        ('directiva_test', 'Directiva Test', group_dir, 'internal'),
        ('entrenadora_test', 'Entrenadora Test', group_ent, 'internal'),
        ('patinadora_test', 'Patinadora Test', group_pat, 'portal'),
    ]

    for login, name, group, user_type in users_to_fix:
        # Busquem el partner de prova associat a aquest usuari (pot no existir)
        partner = env.ref(TEST_USER_PARTNERS[login], raise_if_not_found=False)

        # Valors comuns: contrasenya i grup funcional específic del rol
        vals = {
            'password': 'odoo123',
            'groups_id': [(4, group.id)],  # (4, id) = afegir grup sense eliminar els altres
        }

        # Si existeix el partner de prova, l'associem a l'usuari
        if partner:
            vals['partner_id'] = partner.id

        # Assignem el tipus d'usuari: intern o portal (mutuament excloents a Odoo)
        if user_type == 'internal':
            # (4, ...) afegeix el grup; (3, ...) desenllaça sense eliminar
            vals['groups_id'] += [(4, group_internal.id), (3, group_portal.id)]
        else:
            vals['groups_id'] += [(4, group_portal.id), (3, group_internal.id)]

        # Comprovem si l'usuari ja existeix (per login)
        user = env['res.users'].search([('login', '=', login)], limit=1)
        if user:
            # Si ja existeix, actualitzem els seus valors
            user.write(vals)
        else:
            # Si no existeix, el creem amb login, nom i la resta de valors
            env['res.users'].create({
                'login': login,
                'name': name,
                **vals,  # desempaquetem el diccionari vals dins del create
            })

    # Un cop creats els usuaris, assegurem que existeix la inscripció de prova
    ensure_patinadora_inscripcio(env)


def ensure_patinadora_inscripcio(env):
    # Busquem el partner de la patinadora de prova; si no existeix, no fem res
    partner = env.ref('patinatge_inscripcio.partner_patinadora_test', raise_if_not_found=False)
    if not partner:
        return

    # Comprovem si ja existeix una inscripció amb la referència de prova
    inscripcio = env['patinatge.inscripcio'].search([
        ('reference', '=', TEST_PATINADORA_REF)
    ], limit=1)

    # Valors de la inscripció de prova
    vals = {
        'reference': TEST_PATINADORA_REF,
        'partner_id': partner.id,
        'nom_patinadora': 'Patinadora Test',
        'cognoms_patinadora': 'Test',
        'data_naixement': '2012-05-10',
        'categoria': 'iniciacio',
        'nom_tutor': 'Tutor/a Test',
        'dni_tutor': '00000000T',
        'telefon_tutor': '600000000',
        'email_tutor': 'patinadora_test@example.com',
    }

    if inscripcio:
        # Si ja existeix, només actualitzem el partner_id per garantir la consistència
        inscripcio.write({'partner_id': partner.id})
    else:
        # Si no existeix, creem la inscripció completa
        env['patinatge.inscripcio'].create(vals)


# Hook que s'executa quan es desinstal·la el mòdul
def uninstall_hook(cr, registry):
    # Creem un entorn Odoo amb permisos de superusuari
    env = api.Environment(cr, SUPERUSER_ID, {})

    # Busquem la inscripció de prova, incloent les arxivades (active_test=False)
    inscripcio_test = env['patinatge.inscripcio'].with_context(active_test=False).search([
        ('reference', '=', TEST_PATINADORA_REF)
    ])
    if inscripcio_test:
        # Eliminem definitivament la inscripció de prova
        inscripcio_test.unlink()
        print(f"Inscripció de prova eliminada: {TEST_PATINADORA_REF}")

    # Busquem tots els usuaris de prova, incloent els arxivats
    users = env['res.users'].with_context(active_test=False).search([
        ('login', 'in', TEST_USERS)
    ])
    if users:
        # Eliminem definitivament els usuaris de prova de la base de dades
        users.unlink()
        print(f"Usuaris eliminats: {TEST_USERS}")