# Exercici pràctic 3: Afegir servidor de correu a l’entorn Docker d’Odoo
## Introducció
Com hem vist al Tema 2, quan configurem les dades de l’empresa en Odoo cal definir un servidor de correu d'eixida' (SMTP) per a notificacions, factures i validacions. En desenvolupament no és recomanable usar un servidor real: convé utilitzar una ferramenta de simulació que intercepte els correus per a provar plantilles i fluxos sense enviaments reals. En esta pràctica integrarem MailHog per a fer aquesta simulació de manera segura dins de Docker.

## 🎯 Objectiu

En aquesta pràctica aprendrem a **simular un servidor de correu electrònic** dins del nostre entorn Docker d’Odoo utilitzant **MailHog**.

MailHog ens permet:
- Comprovar que Odoo **envia correus correctament** (com factures, notificacions o missatges automàtics).  
- Veure **el contingut del missatge** (HTML, text, adjunts...).  
- Evitar l’ús de **servidors SMTP reals** o comptes personals com Gmail durant el desenvolupament.  

És una eina molt útil quan estem **desenvolupant mòduls** o provant funcionalitats de notificació dins d’un entorn **controlat**.

---

## 🧠 Context previ

Quan Odoo envia un correu, no ho fa directament:  
1. Crea el missatge amb el mòdul `mail`.  
2. Busca un **servidor SMTP** configurat.  
3. Li passa el missatge a eixe servidor, que és qui l’entrega (enviament real).  

En el nostre entorn de desenvolupament, **no tenim ni volem un servidor real**.  
Així que simularem aquest pas amb **MailHog**, que rep els correus però **no els envia**.  
Els mostra en una **interfície web** que podrem obrir al navegador.

---

## 🧰 Materials i requisits

- Tenir Docker ja instal·lat (com en la pràctica base del servidor Odoo).  
- Tindre un projecte amb el fitxer `docker-compose.yml` funcional.  
- Accés a Odoo des de `http://localhost:8069`.

---

## 🪜 Passos de la pràctica

### 🔹 Pas 1: Entendre què farem
Afegirem un **nou servei Docker** al nostre projecte, anomenat `mailhog`.  
Aquest servei actuarà com a **servidor SMTP local** i tindrà una **interfície web** per vore els missatges enviats.

Per a fer-ho, modificarem el fitxer `docker-compose.yml`.

---

### 🔹 Pas 2: Afegir el servei `mailhog`

Al final del fitxer `docker-compose.yml`, **sota els serveis existents**, copia i enganxa aquest bloc:

```yaml
  mailhog:
    image: mailhog/mailhog:latest
    container_name: mailhog
    ports:
      - "8025:8025"   # Interfície web (on veurem els correus)
      - "1025:1025"   # Port SMTP que utilitzarà Odoo per enviar
    restart: always
```

📘 **Explicació:**
- `image: mailhog/mailhog:latest` → diu a Docker que use la imatge oficial de MailHog.  
- `container_name` → nom identificatiu del contenidor.  
- `ports` → obrim dos ports:  
  - 8025 → per accedir via navegador.  
  - 1025 → per enviar correus des d’Odoo (port SMTP).  
- `restart: always` → fa que s’inicie automàticament si es reinicia el sistema o el contenidor.

---

### 🔹 Pas 3: Connectar Odoo amb MailHog

Dins del mateix fitxer, busca el servei `web:` (Odoo).  
A dins del bloc `depends_on`, afegeix una línia més:

```yaml
    depends_on:
      - db
      - mailhog    # 🔹 Nou: fa que Odoo espere MailHog abans d’arrancar
```

📘 **Explicació:**
Això assegura que **MailHog** ja està actiu quan Odoo intente enviar correus.  
Sense aquest pas, Odoo podria arrencar abans que MailHog estiga llest.

---

### 🔹 Pas 4: Tornar a alçar els contenidors

Guarda el fitxer i, dins del directori del projecte, executa:

```bash
docker compose up -d
```

Això reconstruirà i llançarà els tres serveis:
- Odoo (`web`)
- PostgreSQL (`db`)
- MailHog (`mailhog`)

Per comprovar-ho:
```bash
docker ps
```

Veràs una línia semblant a:
```
mailhog/mailhog:latest   ...   0.0.0.0:1025->1025/tcp, 0.0.0.0:8025->8025/tcp
```

---

### 🔹 Pas 5: Configurar Odoo perquè use MailHog

Ara anem dins de l’aplicació Odoo:

1. Accedeix a `http://localhost:8069`
2. Entra com a administrador (`admin` / la contrasenya definida al teu script).
3. Ves a:
   ```
   Configuració → Discussió → Servidors de correu electrònic personalitzats → Servidors de correu electrònic sortints
   ```
4. Fes clic a “Nou” i posa:

| Paràmetre | Valor |
|------------|--------|
| Nom | MailHog (local) |
| Servidor SMTP | `mailhog` |
| Port | `1025` |
| TLS/SSL | ❌ Desactivat |
| Autenticació | ❌ Cap |
| Usuari / Contrasenya | (en blanc) |
| Remitent | `admin@localhost` |

Fes clic a **Provar connexió**.  
Si tot està bé, apareixerà el missatge:  
✅ *Connexió amb el servidor establida correctament.*


![Visualització del correu en MailHog](/_static/assets/img/Tema3/mailhog-test.png)

---

### 🔹 Pas 6: Fer una prova real

Ara que Odoo ja té configurat el servidor **MailHog**, farem una prova per comprovar que realment pot **enviar correus** i que **MailHog els rep**.

#### 1️⃣ Entra al mòdul *Contactes*

Accedeix a `Contactes` des del menú superior d’Odoo.  
Selecciona qualsevol contacte (per exemple, *Administrator*) o crea’n un de nou.

Fes clic a **Enviar missatge** al peu de la fitxa i escriu un text senzill, com ara:

> Hola!!  
> Prova de correu amb MailHog 🚀

Fes clic a **Enviar**.

![Enviar missatge des de Contactes](/_static/assets/img/Tema3/mailhog-test2.png)

📘 **Explicació:**  
Quan envies el missatge, Odoo no contacta amb Gmail ni amb cap servidor real.  
El que fa és passar el correu al servidor SMTP *mailhog*, que està corrent dins del nostre `docker-compose`.

---

#### 2️⃣ Comprova la recepció en MailHog

Obri el navegador i entra a:

👉 **http://localhost:8025**

Apareixerà la interfície web de MailHog, on veuràs la llista de correus rebuts.  
Fes clic sobre el missatge per obrir-lo i podràs veure:

- El **remitent** i el **destinatari** (`admin@example.com`)
- L’**assumpte** i el contingut del missatge
- Les diferents pestanyes: *HTML*, *Plain text*, *Source*, *MIME*

![Missatge complet a MailHog](/_static/assets/img/Tema3/mailhog-test3.png)


---

#### 3️⃣ Resultat esperat

Si tot està configurat correctament, MailHog mostrarà el correu exactament com Odoo l’hauria enviat realment, amb el teu logo i peu de pàgina si l'has configurat.

En la part superior, també pots descarregar el missatge o consultar-ne el codi font.


---

📘 **Conclusió d’aquest pas:**
Has comprovat que:
- Odoo genera el missatge correctament.
- MailHog el rep i el mostra en la interfície web.
- No s’ha fet cap enviament real fora del teu entorn de desenvolupament.

A partir d’ací, qualsevol mòdul o plantilla que envie correus (com factures, notificacions o recordatoris) es pot provar amb total seguretat.

---


## 💬 Reflexió final

MailHog és una **eina imprescindible per a desenvolupadors Odoo**:  
- Permet provar funcionalitats de correu sense fer enviaments reals.  
- Ajuda a depurar plantilles (`mail.template`) i accions automàtiques.  
- Evita errors de connexió o bloquejos de ports SMTP externs.  
- Tot queda dins del nostre entorn Docker, net i controlat.

💡 En resum:  
> MailHog ens permet **simular el correu real dins del nostre entorn de desenvolupament**, fent que les proves siguen segures i eficients.

---

## ✅ Tasques d’avaluació

1. Explica amb les teues paraules per a què serveix MailHog dins d’un entorn de desenvolupament.  
2. Quina diferència hi ha entre el port 1025 i el 8025?  
3. Quins avantatges té utilitzar MailHog en lloc d’un servidor real?  
4. Mostra una captura de pantalla del correu enviat des d’Odoo i vist a MailHog.
