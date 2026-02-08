# Annex E: Redis com a Cache i Broker de Missatges per a Odoo

Redis transforma Odoo d'una aplicació funcional en una solució empresarial d'alt rendiment. Aquest annex explica què és Redis, per què és fonamental per a entorns Odoo de producció, i com implementar-lo correctament tant en instal·lacions tradicionals com amb Docker.

---

## Introducció a Redis

### Què és Redis?

**Redis** (Remote Dictionary Server) és una base de dades **en memòria** de tipus clau-valor que funciona com a **sistema de cache** ultraràpid i **broker de missatges** per a aplicacions distribuïdes. La seva principal característica és que emmagatzema totes les dades a la RAM, permetent accessos en microsegons.

::: {admonition} Concepte clau: Redis com a accelerador
:class: tip
**Analogia de la biblioteca**: Imagina PostgreSQL com una gran biblioteca amb milions de llibres (dades permanents). Redis seria com la teva taula d'estudi on guardes temporalment els llibres que estàs consultant més sovint. En lloc d'anar cada vegada a buscar el llibre a la biblioteca (lent), el tens a mà immediata (ultraràpid).

**En termes tècnics:**
- PostgreSQL: Disc dur → 5-50ms per consulta
- Redis: Memòria RAM → 0.1-1ms per consulta
- **Millora: 50-500x més ràpid!**
:::

---

## Arquitectura Redis + Odoo

```{mermaid}
graph TD
    A[👥 Usuaris Web] --> B[🌐 Apache/Nginx]
    B --> C[🐍 Odoo Web Server]
    C --> D[🐘 PostgreSQL]
    C --> E[⚡ Redis Cache]

    F[📧 Email Queue] --> E
    G[🔄 Background Jobs] --> E
    H[👤 User Sessions] --> E
    I[🗃️ Query Cache] --> E
    J[🔔 Notifications] --> E

    style E fill:#ff6b6b,color:#fff
    style C fill:#45b7d1,color:#fff
    style D fill:#4ecdc4,color:#fff
```

---

## Redis i Odoo: dos nivells d’ús

### 🔹 Nivell bàsic (Odoo 16 sense mòduls externs)

En Odoo 16, Redis es pot utilitzar directament per a **cache de sessions** i coordinació entre workers.  
Açò ja millora molt el rendiment en entorns amb usuaris concurrents.

**Configuració a `odoo.conf`:**

```ini
[options]
; === Redis integrat (Odoo 16+) ===
enable_redis = True
redis_host = 127.0.0.1
redis_port = 6379
redis_dbindex = 1

; === Cache de sessions ===
session_cache = True

; === Workers (obligatori per Redis) ===
workers = 4
max_cron_threads = 2

; === Límits de seguretat ===
limit_memory_hard = 2684354560   ; 2,5 GB
limit_memory_soft = 2147483648   ; 2 GB
limit_time_cpu = 600             ; 10 minuts
limit_time_real = 1200           ; 20 minuts
```

**Verificació:**
```bash
redis-cli ping
# → PONG

sudo systemctl restart odoo
tail -f /var/log/odoo/odoo.log | grep -i redis
```

---

### 🔹 Nivell avançat (amb mòduls OCA)

Amb mòduls externs (OCA) Redis es converteix en un **broker complet** per a Odoo:

- Cache de consultes de base de dades  
- Enviament massiu de correus sense bloquejar  
- Generació d’informes pesats en segon pla  
- Integració amb APIs externes  
- Comunicació entre múltiples workers  

---

#### Exemple conceptual de cache de consultes

```python
# Sense Redis: cada consulta va a PostgreSQL (~100ms)
users = db.execute("SELECT * FROM res_users WHERE active=true")

# Amb Redis: la primera consulta va a PostgreSQL, les següents al cache (~2ms)
cached_users = redis.get("active_users")
if cached_users:
    users = json.loads(cached_users)
else:
    users = db.execute("SELECT * FROM res_users WHERE active=true")
    redis.setex("active_users", 300, json.dumps(users))  # Cache 5min
```

---

#### Impacte mesurable en el rendiment

| Operació             | Sense Redis | Amb Redis | Millora            |
|----------------------|-------------|-----------|--------------------|
| Login d'usuari      | 2-3 segons  | 0.3-0.5 s | 83% més ràpid      |
| Càrrega dashboard    | 1.5-2 s     | 0.2-0.4 s | 80% més ràpid      |
| Consultes repetides  | 50-200ms    | 1-5ms     | 95% més ràpid      |
| Generació reports    | Bloqueja UI | Background | UX perfecta        |
| Enviament emails     | Sincrònic   | Asíncron  | 0% blocking        |

---

## Quan és imprescindible Redis?

::: {admonition} Redis és OBLIGATORI quan:
:class: error
- Més de 10 usuaris concurrents  
- Múltiples workers d'Odoo (entorns de producció)  
- Processament automàtic de correus  
- Reports que triguen més d'1 minut  
- Integració amb APIs externes  
- Necessitat de tasques programades  
:::

::: {admonition} Redis és RECOMANABLE quan:
:class: warning
- 5-10 usuaris concurrents  
- Base de dades amb més de 100k registres  
- Funcionalitats de comerç electrònic  
- Integracions complexes  
- Requisits de rendiment estrictes  
:::

::: {admonition} Redis és OPCIONAL quan:
:class: note
- 1-5 usuaris ocasionals  
- Entorn de desenvolupament local  
- Dades mínimes i operacions simples  
- Recursos de servidor limitats  
:::

---

## Implementació amb Docker

Afegir Redis al teu `docker-compose.yml`:

```yaml
services:
  redis:
    image: redis:7-alpine
    container_name: odoo_redis
    restart: unless-stopped
    ports:
      - "127.0.0.1:6379:6379"  # Només accessible localment
    volumes:
      - redis-data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  web:
    image: odoo:16.0
    depends_on:
      - db
      - redis
    environment:
      - HOST=db
      - USER=odoo
      - PASSWORD=${POSTGRES_PASSWORD}
      - REDIS_HOST=redis

volumes:
  redis-data:
    driver: local
```

---

### Explicació del codi Redis

- **Imatge i contenidor:**
  - `redis:7-alpine`: Utilitza Redis versió 7 sobre Alpine Linux, una distribució ultra-lleugera que redueix la mida de la imatge de ~100MB a ~30MB.
  - `container_name: odoo_redis`: Nom fix per facilitar la gestió i debug.

- **Seguretat de xarxa:**
  - `"127.0.0.1:6379:6379"`: Exposa Redis només a localhost, evitant accessos externs no autoritzats. En producció és crítica aquesta configuració.

- **Persistència de dades:**
  - `redis-data:/data`: Volum anomenat que persisteix les dades de Redis entre reinicis del contenidor.
  - `./config/redis.conf`: Configuració personalitzada montada com a només lectura.

- **Optimització del sistema:**
  - `net.core.somaxconn=511`: Augmenta la cua de connexions TCP pendents de 128 (per defecte) a 511, essencial per aplicacions amb alta concurrència com Odoo.

- **Monitoratge de salut:**
  - `redis-cli ping`: Comprova cada 30 segons que Redis respon amb "PONG".
  - `start_period: 10s`: Dona temps a Redis per inicialitzar-se abans de començar les comprovacions.
  - `retries: 3`: Marca el servei com a no saludable després de 3 fallos consecutius.

- **Integració amb Odoo:**
  - `depends_on: redis`: Assegura que Redis s'inicia abans que Odoo.
  - `REDIS_HOST=redis`: Variable d'entorn que Odoo utilitzarà per connectar-se (utilitza el nom del servei com a hostname dins de la xarxa Docker).

---

### Comandos útils per verificar la configuració

```bash
# Iniciar només Redis per comprovar que funciona
docker-compose up redis

# Verificar connectivitat des d'Odoo
docker-compose exec web python3 -c "
import redis
r = redis.Redis(host='redis', port=6379, db=1)
print('Redis OK!' if r.ping() else 'Redis Error')
"

# Monitorar l'activitat de Redis en temps real
docker-compose exec redis redis-cli monitor
```

---

## Instal·lació i configuració

### Tradicional:

```bash
sudo apt-get update
sudo apt-get install redis-server

# Configuració bàsica
sudo nano /etc/redis/redis.conf
```

### Docker:

```bash
docker run --name redis -d -p 6379:6379 redis:alpine
```

### Comprovació de l'estat de Redis

```bash
# Comprovació ràpida
redis-cli ping

# Hauries de rebre com a resposta:
PONG
```

### Configuració recomanada per a Odoo

```ini
# /etc/redis/redis.conf
maxmemory 2gb
maxmemory-policy allkeys-lru

# Assegura't que aquestes línies estiguin presents i descomentades
supervised systemd
```

---

## Configuració completa d'exemple (Annex tècnic)

```ini
# CONFIGURACIÓ COMPLETA NECESSÀRIA:
[options]
# === CONFIGURACIÓ DE BASE DE DADES ===
db_host = localhost
db_port = 5432
db_user = odoo
db_password = StrongPassword123!
db_sslmode = prefer

# === CONFIGURACIÓ DE WORKERS (OBLIGATORI PER REDIS) ===
# Fórmula: workers = (CPU cores × 2) + 1
workers = 4
max_cron_threads = 2
worker_class = sync

# === CONFIGURACIÓ REDIS ===
# Activa el suport Redis integrat d'Odoo 16
enable_redis = True
redis_host = 127.0.0.1
redis_port = 6379
redis_dbindex = 1
redis_pass = False

# === CACHE DE SESSIONS AMB REDIS ===
session_cache = True
session_cache_size = 100000
session_cache_timeout = 3600  # 1 hora

# === LÍMITS DE MEMÒRIA PER WORKER ===
limit_memory_hard = 2684354560   # 2,5 GB límit dur
limit_memory_soft = 2147483648   # 2 GB límit suau
limit_time_cpu = 600             # 10 minuts CPU màxim
limit_time_real = 1200           # 20 minuts temps real màxim

# === CONFIGURACIÓ GENERAL ===
proxy_mode = True
list_db = False
admin_passwd = $pbkdf2-sha512$25000$hash...

# === LOGGING ===
log_level = info
logfile = /var/log/odoo/odoo.log
log_db = False

# === PATHS ===
addons_path = /usr/lib/python3/dist-packages/odoo/addons
data_dir = /var/lib/odoo
```

---

## Notes finals

- Redis ha d’estar **sempre protegit** (bind a `127.0.0.1` o xarxa privada Docker).  
- Amb **Odoo 16 bàsic**, Redis cobreix **sessions i workers**.  
- Amb **mòduls OCA**, Redis es converteix en un **broker complet** que accelera consultes, cues i notificacions.  



