# Apache com a Reverse Proxy per a Odoo

Aquest annex cobreix la configuració d'Apache HTTP Server com a reverse proxy per a Odoo, una configuració essencial per a entorns de producció que requereixen SSL, gestió de tràfic, seguretat avançada i compliment normatiu.

## Introducció al Reverse Proxy

### Què és un reverse proxy?

Un reverse proxy és un servidor que actua com a intermediari entre els clients i el servidor backend (Odoo). A diferència d'un proxy forward que actua en nom del client, un reverse proxy actua en nom del servidor.

```{mermaid}
graph LR
    A[Client] --> B[Apache Reverse Proxy]
    B --> C[Odoo Port 8069]
    B --> D[PostgreSQL Port 5432]
    B --> E[Fitxers Estàtics]
```

### Avantatges del reverse proxy per a Odoo

:::{admonition} Beneficis principals
:class: tip
**Seguretat:**
- Ocultació del servidor backend
- Terminació SSL/TLS centralitzada
- Filtratge de peticions malicioses
- Control d'accés granular

**Rendiment:**
- Cache de contingut estàtic
- Compressió automàtica
- Load balancing entre múltiples instàncies
- Optimització de connexions

**Gestió:**
- Logs centralitzats
- Manteniment sense interrupcions
- Certificats SSL unificats
- Redirections i reescriptures d'URL
:::

## Instal·lació i configuració bàsica

### 1) Instal·lació d'Apache

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y apache2

# CentOS/RHEL
sudo yum install httpd
sudo systemctl enable httpd
```

### 2) Activació de mòduls necessaris

```bash
# Mòduls essencials per a reverse proxy
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod proxy_balancer
sudo a2enmod lbmethod_byrequests

# Mòduls per a SSL i seguretat
sudo a2enmod ssl
sudo a2enmod headers
sudo a2enmod rewrite

# Mòduls per a rendiment
sudo a2enmod expires
sudo a2enmod deflate

# Verificar mòduls actius
apache2ctl -M | grep -E "(proxy|ssl|headers)"
```

**Explicació dels mòduls:**

- `proxy`: Funcionalitat bàsica de proxy
- `proxy_http`: Suport per a protocol HTTP
- `proxy_balancer`: Load balancing entre múltiples backends
- `ssl`: Suport per a HTTPS/TLS
- `headers`: Manipulació de capçaleres HTTP
- `rewrite`: Reescriptura d'URLs
- `expires`: Control de cache
- `deflate`: Compressió de contingut

## Configuració del VirtualHost

### Configuració bàsica HTTP

```apache
# /etc/apache2/sites-available/odoo-http.conf
<VirtualHost *:80>
    ServerName odoo.empresa.com
    ServerAlias www.odoo.empresa.com
    
    # Redirigir tot el tràfic a HTTPS
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
    
    # Logs específics
    ErrorLog ${APACHE_LOG_DIR}/odoo_error.log
    CustomLog ${APACHE_LOG_DIR}/odoo_access.log combined
</VirtualHost>
```

### Configuració HTTPS amb seguretat avançada

```apache
# /etc/apache2/sites-available/odoo-https.conf
<VirtualHost *:443>
    ServerName odoo.empresa.com
    ServerAlias www.odoo.empresa.com
    
    # Configuració SSL bàsica
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/odoo.empresa.com.crt
    SSLCertificateKeyFile /etc/ssl/private/odoo.empresa.com.key
    SSLCertificateChainFile /etc/ssl/certs/ca-certificates.crt
    
    # Configuració SSL avançada
    SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder on
    SSLCompression off
    SSLSessionTickets off
    
    # OCSP Stapling (validació de certificats)
    SSLUseStapling on
    SSLStaplingResponderTimeout 5
    SSLStaplingReturnResponderErrors off
    SSLStaplingCache shmcb:/var/run/ocsp(128000)
    
    # Configuració del proxy principal
    ProxyPreserveHost On
    ProxyRequests Off
    
    # Timeouts per a millor rendiment
    ProxyTimeout 600
    ProxyBadHeader Ignore
    
    # Proxy per a longpolling (notificacions temps real)
    ProxyPass /longpolling/ http://127.0.0.1:8072/ retry=1 acquire=3000 timeout=600 Keepalive=On
    ProxyPassReverse /longpolling/ http://127.0.0.1:8072/
    
    # Proxy principal per a Odoo
    ProxyPass /web/static/ !
    ProxyPass / http://127.0.0.1:8069/ retry=1 acquire=3000 timeout=600 Keepalive=On
    ProxyPassReverse / http://127.0.0.1:8069/
    
    # Capçaleres de seguretat i compliment RGPD
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Permissions-Policy "geolocation=(), microphone=(), camera=(), payment=()"
    
    # Content Security Policy per a Odoo
    Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline' fonts.googleapis.com; img-src 'self' data: https:; font-src 'self' fonts.gstatic.com; connect-src 'self'; frame-ancestors 'self'"
    
    # Gestió optimitzada de fitxers estàtics
    Alias /web/static/ /opt/odoo/odoo/addons/web/static/
    <Directory /opt/odoo/odoo/addons/web/static/>
        Require all granted
        
        # Cache agressiu per a estàtics
        ExpiresActive On
        ExpiresDefault "access plus 1 month"
        ExpiresByType text/css "access plus 1 year"
        ExpiresByType application/javascript "access plus 1 year"
        ExpiresByType image/png "access plus 1 year"
        ExpiresByType image/jpg "access plus 1 year"
        ExpiresByType image/jpeg "access plus 1 year"
        ExpiresByType image/gif "access plus 1 year"
        ExpiresByType image/svg+xml "access plus 1 year"
        
        # Capçaleres de cache
        Header append Vary Accept-Encoding
        Header set Cache-Control "public, max-age=31536000, immutable"
        
        # Compressió
        SetOutputFilter DEFLATE
        SetEnvIfNoCase Request_URI \
            \.(?:gif|jpe?g|png)$ no-gzip dont-vary
        SetEnvIfNoCase Request_URI \
            \.(?:exe|t?gz|zip|bz2|sit|rar)$ no-gzip dont-vary
    </Directory>
    
    # Control de cache per a dades sensibles
    <LocationMatch "\.(py|conf|xml)$">
        Header always set Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate"
        Header always set Pragma "no-cache"
        Header always set Expires "0"
    </LocationMatch>
    
    # Protecció contra robots maliciosos
    <LocationMatch "^/(web/database|web/session)">
        # Limitar rate per IP
        <RequireAll>
            Require all granted
            Require not env bad_bot
        </RequireAll>
    </LocationMatch>
    
    # Logs detallats amb format personalitzat
    LogFormat "%h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\" %D" odoo_combined
    ErrorLog ${APACHE_LOG_DIR}/odoo_ssl_error.log
    CustomLog ${APACHE_LOG_DIR}/odoo_ssl_access.log odoo_combined
</VirtualHost>
```

### Explicació detallada de la configuració

**Configuració SSL avançada:**
- `SSLProtocol`: Només permet TLS 1.2 i 1.3 (elimina protocols insegurs)
- `SSLCipherSuite`: Conjunt de xifratges moderns i segurs
- `SSLHonorCipherOrder`: Prioritza l'ordre del servidor
- `SSLCompression off`: Evita atacs CRIME
- `SSLUseStapling`: Millora el rendiment de validació de certificats

**Configuració del proxy:**
- `ProxyPreserveHost On`: Manté el nom del host original
- `retry=1`: Un intent de reconnexió en cas d'error
- `acquire=3000`: Temps màxim per obtenir connexió (3s)
- `timeout=600`: Timeout de 10 minuts per a operacions llargues
- `Keepalive=On`: Reutilitza connexions TCP

**Capçaleres de seguretat RGPD:**
- `Strict-Transport-Security`: Força HTTPS durant un any
- `Referrer-Policy`: Limita informació enviada a dominis externs
- `Permissions-Policy`: Desactiva APIs sensibles per defecte
- `Content-Security-Policy`: Prevé XSS i injeccions de codi

## Configuració d'Odoo per a Reverse Proxy

### Modificació d'odoo.conf

```ini
# /etc/odoo/odoo.conf - Configuració per treballar amb Apache
[options]
# ... configuració anterior ...

# Configuració essencial per a reverse proxy
proxy_mode = True

# Interfície i ports
xmlrpc_interface = 127.0.0.1
xmlrpc_port = 8069
longpolling_port = 8072

# Només acceptar connexions locals (Apache fa de proxy)
netrpc_interface = 127.0.0.1

# Configuració de workers per a millor rendiment
workers = 4
max_cron_threads = 2

# Límits de memòria i temps
limit_memory_hard = 2684354560  # 2.5 GB
limit_memory_soft = 2147483648  # 2 GB
limit_time_cpu = 600
limit_time_real = 1200
limit_request = 8192

# Log més detallat per a debugging
log_level = info
log_handler = :INFO,werkzeug:CRITICAL,odoo.addons.base.models.ir_mail_server:WARNING
```

**Explicació de la configuració:**

**Seguretat:**
- `proxy_mode = True`: Indica a Odoo que treballa darrere d'un proxy
- `xmlrpc_interface = 127.0.0.1`: Només escolta connexions locals
- Apache s'encarrega de l'accés extern i la seguretat

**Rendiment:**
- `workers = 4`: Processos workers segons CPU disponibles
- `max_cron_threads = 2`: Fils per a tasques programades
- Límits de memòria i temps per evitar bloquejos

## SSL amb Let's Encrypt

### Instal·lació automàtica

```bash
# Instal·lar Certbot per a Apache
sudo apt install certbot python3-certbot-apache

# Obtenir certificat automàticament
sudo certbot --apache -d odoo.empresa.com -d www.odoo.empresa.com

# Verificar configuració
sudo certbot certificates

# Test de renovació
sudo certbot renew --dry-run
```

### Configuració manual de certificats

```bash
# Obtenir certificat només
sudo certbot certonly --webroot -w /var/www/html -d odoo.empresa.com

# Crear enllaços simbòlics per a Apache
sudo ln -s /etc/letsencrypt/live/odoo.empresa.com/fullchain.pem /etc/ssl/certs/odoo.empresa.com.crt
sudo ln -s /etc/letsencrypt/live/odoo.empresa.com/privkey.pem /etc/ssl/private/odoo.empresa.com.key
```

### Renovació automàtica

```bash
# Script de renovació amb recàrrega d'Apache
# /etc/cron.daily/certbot-renew

#!/bin/bash
certbot renew --quiet --post-hook "systemctl reload apache2"

# Fer executable
sudo chmod +x /etc/cron.daily/certbot-renew
```

## Configuració de Load Balancing

Per a entorns d'alta disponibilitat amb múltiples instàncies d'Odoo:

```apache
# /etc/apache2/sites-available/odoo-cluster.conf
<VirtualHost *:443>
    ServerName odoo.empresa.com
    
    # ... configuració SSL anterior ...
    
    # Definició del cluster de backends
    ProxyPreserveHost On
    
    <Proxy balancer://odoo-cluster>
        BalancerMember http://127.0.0.1:8069 route=odoo1
        BalancerMember http://127.0.0.1:8070 route=odoo2
        BalancerMember http://127.0.0.1:8071 route=odoo3
        ProxySet lbmethod=byrequests
        ProxySet stickysession=ROUTEID
    </Proxy>
    
    <Proxy balancer://odoo-longpolling>
        BalancerMember http://127.0.0.1:8072 route=odoo1
        BalancerMember http://127.0.0.1:8073 route=odoo2  
        BalancerMember http://127.0.0.1:8074 route=odoo3
        ProxySet lbmethod=byrequests
    </Proxy>
    
    # Configuració del balanceador
    ProxyPass /balancer-manager !
    ProxyPass /longpolling/ balancer://odoo-longpolling/
    ProxyPass / balancer://odoo-cluster/
    ProxyPassReverse / balancer://odoo-cluster/
    
    # Gestor del balanceador (accés restringit)
    <Location "/balancer-manager">
        SetHandler balancer-manager
        Require ip 192.168.1.0/24
        Require ip 127.0.0.1
    </Location>
</VirtualHost>
```

## Monitoratge i logs

### Configuració de logs avançats

```apache
# Logs personalitzats per a Odoo
LogFormat "%h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\" %D %{SSL_PROTOCOL}x %{SSL_CIPHER}x" odoo_ssl_combined

# Rotació de logs
LogRotate "weekly"
LogRotateOptions "compress delay"
LogRotateSize 100M
```

### Script de monitoratge

```bash
#!/bin/bash
# /usr/local/bin/monitor-apache-odoo.sh

# Variables
LOG_FILE="/var/log/apache2/odoo_ssl_access.log"
ERROR_LOG="/var/log/apache2/odoo_ssl_error.log"
ALERT_EMAIL="admin@empresa.com"

# Comprovar errors SSL
SSL_ERRORS=$(tail -n 100 $ERROR_LOG | grep -c "SSL")
if [ $SSL_ERRORS -gt 10 ]; then
    echo "⚠️ ALERTA: $SSL_ERRORS errors SSL detectats" | mail -s "Apache SSL Issues" $ALERT_EMAIL
fi

# Comprovar temps de resposta lent
SLOW_REQUESTS=$(tail -n 1000 $LOG_FILE | awk '$NF > 5000000 { count++ } END { print count+0 }')
if [ $SLOW_REQUESTS -gt 5 ]; then
    echo "⚠️ ALERTA: $SLOW_REQUESTS peticions lentes (>5s)" | mail -s "Odoo Performance Warning" $ALERT_EMAIL
fi

# Comprovar status d'Apache
if ! systemctl is-active --quiet apache2; then
    echo "🚨 CRÍTIC: Apache no està funcionant" | mail -s "Apache Down" $ALERT_EMAIL
    systemctl restart apache2
fi

# Estadístiques de tràfic
TODAY=$(date +%Y-%m-%d)
REQUESTS_TODAY=$(grep $TODAY $LOG_FILE | wc -l)
echo "📊 Peticions avui: $REQUESTS_TODAY"

# Top 10 IPs més actives
echo "🌐 Top 10 IPs:"
grep $TODAY $LOG_FILE | awk '{print $1}' | sort | uniq -c | sort -nr | head -10
```

### Integració amb fail2ban

```ini
# /etc/fail2ban/jail.local
[odoo-apache]
enabled = true
port = http,https
filter = odoo-apache
logpath = /var/log/apache2/odoo_ssl_access.log
maxretry = 10
bantime = 3600
findtime = 600

# Crear filtre personalitzat
# /etc/fail2ban/filter.d/odoo-apache.conf
[Definition]
failregex = ^<HOST> .* "(GET|POST) /web/database/manager.*" 40[0-9] .*$
            ^<HOST> .* "(GET|POST) /web/session/authenticate.*" 40[0-9] .*$
ignoreregex =
```

## Verificació i testing

### Scripts de verificació

```bash
#!/bin/bash
# test-apache-odoo.sh

URL_BASE="https://odoo.empresa.com"

echo "🔍 Testing configuració Apache + Odoo..."

# Test SSL
echo "🔒 Verificant SSL..."
SSL_GRADE=$(curl -s "https://api.ssllabs.com/api/v3/analyze?host=odoo.empresa.com" | jq -r '.endpoints[0].grade')
echo "SSL Labs Grade: $SSL_GRADE"

# Test capçaleres de seguretat
echo "🛡️ Verificant capçaleres de seguretat..."
HEADERS=$(curl -sI $URL_BASE)

echo "$HEADERS" | grep -q "Strict-Transport-Security" && echo "✅ HSTS activat" || echo "❌ HSTS no trobat"
echo "$HEADERS" | grep -q "X-Frame-Options" && echo "✅ X-Frame-Options activat" || echo "❌ X-Frame-Options no trobat"
echo "$HEADERS" | grep -q "Content-Security-Policy" && echo "✅ CSP activat" || echo "❌ CSP no trobat"

# Test temps de resposta
echo "⏱️ Verificant temps de resposta..."
RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}\n' $URL_BASE)
echo "Temps de resposta: ${RESPONSE_TIME}s"

# Test longpolling
echo "🔗 Verificant longpolling..."
LONGPOLL_STATUS=$(curl -s -o /dev/null -w '%{http_code}' "$URL_BASE/longpolling/poll")
echo "Status longpolling: $LONGPOLL_STATUS"

# Test load balancer (si està configurat)
echo "⚖️ Verificant balanceador..."
BALANCER_STATUS=$(curl -s -o /dev/null -w '%{http_code}' "$URL_BASE/balancer-manager")
if [ "$BALANCER_STATUS" = "200" ]; then
    echo "✅ Balanceador accessible"
else
    echo "ℹ️ Balanceador no configurat o no accessible"
fi

echo "✅ Tests completats!"
```

### Benchmark de rendiment

```bash
#!/bin/bash
# benchmark-apache-odoo.sh

echo "📊 Executant benchmark de rendiment..."

# Test amb ab (Apache Bench)
echo "🚀 Test de concurrència..."
ab -n 1000 -c 10 -H "Accept-Encoding: gzip,deflate" https://odoo.empresa.com/web/login

# Test amb curl per a diferents endpoints
echo "📋 Test d'endpoints principals..."

ENDPOINTS=(
    "/web/login"
    "/web/database/selector"
    "/web/static/src/css/bootstrap.css"
    "/web/static/src/js/chrome/abstract_web_client.js"
)

for endpoint in "${ENDPOINTS[@]}"; do
    echo "Testing $endpoint..."
    TIME=$(curl -o /dev/null -s -w '%{time_total}\n' "https://odoo.empresa.com$endpoint")
    SIZE=$(curl -o /dev/null -s -w '%{size_download}\n' "https://odoo.empresa.com$endpoint")
    echo "  Temps: ${TIME}s, Mida: ${SIZE} bytes"
done
```

## Resolució de problemes habituals

### Problemes de configuració SSL

```bash
# Verificar configuració SSL
sudo apache2ctl configtest

# Test manual de certificats
openssl s_client -connect odoo.empresa.com:443 -servername odoo.empresa.com

# Verificar chains de certificats
openssl x509 -in /etc/ssl/certs/odoo.empresa.com.crt -text -noout
```

### Problemes de proxy

```bash
# Verificar connexió al backend
telnet localhost 8069

# Test manual del proxy
curl -H "Host: odoo.empresa.com" http://localhost/web/login

# Logs en temps real
sudo tail -f /var/log/apache2/odoo_ssl_error.log
```

### Problemes de rendiment

```bash
# Estadístiques d'Apache
sudo apache2ctl fullstatus

# Connexions actives
sudo netstat -plan | grep :443 | wc -l

# Processos Apache
ps aux | grep apache2
```

## Configuració de seguretat avançada

### Protecció contra atacs DDoS

```apache
# Mòdul mod_security (instal·lar per separat)
LoadModule security2_module modules/mod_security2.so

<IfModule mod_security2.c>
    SecRuleEngine On
    SecRequestBodyAccess On
    SecDefaultAction "phase:2,deny,log,status:406"
    
    # Protecció contra SQL injection
    SecRule ARGS "@detectSQLi" "id:1001,phase:2,deny,log,msg:'SQL Injection Attack'"
    
    # Limitació de mida de peticions
    SecRequestBodyLimit 104857600
    SecRequestBodyNoFilesLimit 131072
</IfModule>

# Limitació de rate per IP
<IfModule mod_limitipconn.c>
    ExtendedStatus On
    <Location />
        MaxConnPerIP 20
        NoIPLimit image/*
    </Location>
</IfModule>
```

### Configuració de firewall específica

```bash
# IPtables rules específiques per a Apache + Odoo
sudo iptables -A INPUT -p tcp --dport 80 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT

# Bloquejar accés directe als ports d'Odoo
sudo iptables -A INPUT -p tcp --dport 8069 -s 127.0.0.1 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8069 -j DROP
sudo iptables -A INPUT -p tcp --dport 8072 -s 127.0.0.1 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8072 -j DROP
```

## Conclusions

La configuració d'Apache com a reverse proxy per a Odoo proporciona:

:::{admonition} Beneficis assolits
:class: success
**Seguretat:**
- ✅ Terminació SSL/TLS professional
- ✅ Capçaleres de seguretat per compliment RGPD
- ✅ Ocultació del backend Odoo
- ✅ Protecció contra atacs comuns

**Rendiment:**
- ✅ Cache de contingut estàtic optimitzat
- ✅ Compressió automàtica
- ✅ Load balancing per a alta disponibilitat
- ✅ Gestió eficient de connexions

**Manteniment:**
- ✅ Logs centralitzats i detallats
- ✅ Monitoratge automatitzat
- ✅ Renovació automàtica de certificats
- ✅ Gestió professional de la infraestructura
:::

Aquesta configuració és essencial per a qualsevol desplegament d'Odoo en producció que requereixi estàndards professionals de seguretat, rendiment i manteniment.

