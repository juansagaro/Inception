# Inception - Guía de Estudio para la Defensa

Este documento está diseñado para prepararte exhaustivamente para la evaluación del proyecto Inception en 42. Cubre desde los fundamentos teóricos hasta la disección línea por línea del código más crítico.

---

## Tabla de Contenidos

1. [Conceptos Teóricos Clave](#1-conceptos-teóricos-clave)
   - [1.1 Docker Bajo el Capó](#11-docker-bajo-el-capó)
   - [1.2 El Problema del PID 1](#12-el-problema-del-pid-1)
   - [1.3 Máquinas Virtuales vs Contenedores](#13-máquinas-virtuales-vs-contenedores)
2. [Arquitectura del Proyecto](#2-arquitectura-del-proyecto)
   - [2.1 Flujo de una Petición HTTP](#21-flujo-de-una-petición-http)
   - [2.2 Red Interna de Docker](#22-red-interna-de-docker)
   - [2.3 Volúmenes y Persistencia](#23-volúmenes-y-persistencia)
3. [Disección del Código](#3-disección-del-código)
   - [3.1 NGINX: Configuración del Servidor](#31-nginx-configuración-del-servidor)
   - [3.2 FastCGI: Conexión NGINX-PHP](#32-fastcgi-conexión-nginx-php)
   - [3.3 WordPress: Script de Inicialización](#33-wordpress-script-de-inicialización)
   - [3.4 MariaDB: Inicialización Segura](#34-mariadb-inicialización-segura)
   - [3.5 Docker Compose: Orquestación](#35-docker-compose-orquestación)
4. [Glosario de Comandos y Flags](#4-glosario-de-comandos-y-flags)
   - [4.1 Flags de Dockerfiles](#41-flags-de-dockerfiles)
   - [4.2 Comandos del Makefile](#42-comandos-del-makefile)
   - [4.3 Comandos de Servicios](#43-comandos-de-servicios)
5. [Simulación de Defensa: 10 Preguntas Difíciles](#5-simulación-de-defensa-10-preguntas-difíciles)

---

## 1. Conceptos Teóricos Clave

### 1.1 Docker Bajo el Capó

Docker no es una máquina virtual. Es una tecnología de **contenedorización** que aprovecha características del kernel de Linux para aislar procesos. Los tres pilares fundamentales son:

#### Namespaces (Aislamiento)

Los namespaces proporcionan aislamiento a nivel de kernel. Cada contenedor tiene su propia vista del sistema:

| Namespace | Qué Aísla | Ejemplo en Inception |
|-----------|-----------|---------------------|
| **PID** | Árbol de procesos | WordPress ve su PHP-FPM como PID 1, no los procesos del host |
| **NET** | Interfaces de red | Cada contenedor tiene su propia IP en `jsagaro-net` |
| **MNT** | Puntos de montaje | MariaDB ve `/var/lib/mysql` como su volumen, no el del host |
| **UTS** | Hostname | `container_name: nginx` define el hostname del contenedor |
| **IPC** | Comunicación entre procesos | Procesos de WordPress no pueden ver memoria compartida de MariaDB |
| **USER** | UIDs/GIDs | `www-data` en WordPress es diferente del `www-data` del host |

```
┌───────────────────────────────────────────────────────────┐
│                    HOST (Debian VM)                       │
│  ┌─────────────────────────────────────────────────────┐  │
│  │                   KERNEL LINUX                      │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │  │
│  │  │ Namespace 1 │  │ Namespace 2 │  │ Namespace 3 │  │  │
│  │  │   (nginx)   │  │ (wordpress) │  │  (mariadb)  │  │  │
│  │  │  PID=1      │  │  PID=1      │  │  PID=1      │  │  │
│  │  │  nginx      │  │  php-fpm    │  │  mysqld     │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  │  │
│  └─────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────┘
```

#### cgroups (Control de Recursos)

Los Control Groups limitan y contabilizan los recursos que puede usar un contenedor:

- **CPU**: Limitar ciclos de CPU
- **Memoria**: Establecer límites máximos (ej: `maxmemory 128mb` en Redis)
- **I/O de disco**: Limitar velocidad de lectura/escritura
- **Red**: Priorizar tráfico

En Inception, Docker aplica cgroups automáticamente. Si quisieras limitar MariaDB a 512MB:

```yaml
mariadb:
  deploy:
    resources:
      limits:
        memory: 512M
```

#### Union Filesystem (Capas de Imagen)

Docker usa un sistema de archivos en capas. Cada instrucción del Dockerfile crea una capa:

```dockerfile
FROM debian:bookworm          # Capa 1: Sistema base (~120MB)
RUN apt-get update && ...     # Capa 2: Paquetes instalados
COPY ./conf/nginx.conf ...    # Capa 3: Configuración
COPY ./tools/nginx_start.sh   # Capa 4: Script
```

Las capas son **inmutables** y **compartidas**. Si NGINX y el sitio estático usan `debian:bookworm`, comparten la Capa 1.

### 1.2 El Problema del PID 1

En Unix, el proceso con PID 1 (init) tiene responsabilidades especiales:

1. **Adoptar procesos huérfanos**: Si un proceso hijo muere y su padre no lo recoge, PID 1 lo adopta
2. **Manejar señales**: `SIGTERM`, `SIGINT`, etc. para shutdown graceful
3. **Reaping zombies**: Limpiar procesos terminados de la tabla de procesos

#### Por qué `exec` es obligatorio

Sin `exec`:
```bash
#!/bin/bash
# SIN EXEC - MALO
nginx -g "daemon off;"
```

```
PID 1: /bin/bash (script)
  └── PID 2: nginx
```

El script bash es PID 1. Cuando Docker envía `SIGTERM` para parar el contenedor:
- Bash recibe la señal pero no la propaga a nginx
- nginx nunca hace shutdown graceful
- Docker espera timeout (10s) y envía `SIGKILL`
- Posible corrupción de datos

Con `exec`:
```bash
#!/bin/bash
# CON EXEC - CORRECTO
exec nginx -g "daemon off;"
```

```
PID 1: nginx (reemplaza al script)
```

`exec` **reemplaza** el proceso bash por nginx. Ahora nginx es PID 1 y recibe las señales directamente.

#### Verificación en tu proyecto

Cada script de inicio usa `exec` correctamente:

| Servicio | Comando | PID 1 |
|----------|---------|-------|
| NGINX | `exec nginx -g "daemon off;"` | nginx |
| WordPress | `exec php-fpm8.2 -F` | php-fpm8.2 |
| MariaDB | `exec mysqld_safe --init-file=...` | mysqld_safe |
| Redis | `exec redis-server /etc/redis/redis.conf` | redis-server |
| Adminer | `exec php -S 0.0.0.0:8080 -t /var/www/adminer` | php |
| FTP | `exec vsftpd /etc/vsftpd.conf` | vsftpd |
| Portainer | `exec /opt/portainer/portainer ...` | portainer |
| Static | `exec nginx -g "daemon off;"` | nginx |

### 1.3 Máquinas Virtuales vs Contenedores

```
┌────────────────────────────────────────────────────────────────────────┐
│                    MÁQUINA VIRTUAL                                     │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ App A │ App B │ App C │                                          │  │
│  ├───────┴───────┴───────┤                                          │  │
│  │      Guest OS         │  ← Sistema operativo COMPLETO (~GB)      │  │
│  ├───────────────────────┤                                          │  │
│  │      Hypervisor       │  ← Capa de virtualización                │  │
│  ├───────────────────────┤                                          │  │
│  │       Host OS         │                                          │  │
│  ├───────────────────────┤                                          │  │
│  │      Hardware         │                                          │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────┐
│                       CONTENEDOR                                       │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ App A │ App B │ App C │                                          │  │
│  ├───────┴───────┴───────┤                                          │  │
│  │   Docker Engine       │  ← Solo gestiona aislamiento             │  │
│  ├───────────────────────┤                                          │  │
│  │       Host OS         │  ← Kernel COMPARTIDO                     │  │
│  ├───────────────────────┤                                          │  │
│  │      Hardware         │                                          │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

| Aspecto | Máquina Virtual | Contenedor Docker |
|---------|-----------------|-------------------|
| **Aislamiento** | Completo (kernel propio) | Proceso (kernel compartido) |
| **Tamaño** | GBs (OS completo) | MBs (solo dependencias) |
| **Arranque** | Minutos | Segundos |
| **Overhead** | Alto (hypervisor) | Mínimo |
| **Portabilidad** | Limitada | Alta (imagen = artifact) |
| **Seguridad** | Mayor (aislamiento total) | Menor (comparte kernel) |
| **Uso CPU/RAM** | Reservado estáticamente | Dinámico |

**En Inception**: El proyecto corre en una VM (requisito del subject) que contiene Docker. Esto combina:
- Aislamiento de VM entre tu proyecto y el sistema host de 42
- Eficiencia de contenedores dentro de la VM

---

## 2. Arquitectura del Proyecto

### 2.1 Flujo de una Petición HTTP

Cuando un usuario accede a `https://jsagaro-.42.fr`:

```
┌──────────┐     ┌─────────────────────────────────────────────────────────┐
│ BROWSER  │     │                    DOCKER NETWORK                       │
│          │     │                                                         │
│ 1. DNS   │     │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│ resolve  │────▶│  │   NGINX     │───▶│  WordPress  │───▶│  MariaDB  │  │
│          │     │  │   :443      │    │   :9000     │    │   :3306     │  │
│ 2. TLS   │     │  │             │    │             │    │             │  │
│ handshake│◀───▶│  │ TLSv1.2/1.3 │   │   PHP-FPM   │    │  InnoDB     │  │
│          │     │  └─────────────┘    └──────┬──────┘    └─────────────┘  │
│ 3. HTTP  │     │         │                  │                            │
│ request  │     │         │                  ▼                            │
│          │     │         │           ┌─────────────┐                     │
│ 4. HTML  │     │         │           │   Redis     │                     │
│ response │◀────│        │           │   :6379     │                     │
│          │     │         │           │   (cache)   │                     │
└──────────┘     │         │           └─────────────┘                     │
                 │         │                                               │
                 │         ▼                                               │
                 │  wordpress_data                                         │
                 │  /var/www/html                                          │
                 └─────────────────────────────────────────────────────────┘
```

#### Paso a Paso Detallado:

**1. Resolución DNS**
```
Browser → /etc/hosts → 127.0.0.1 jsagaro-.42.fr
```
El archivo `/etc/hosts` de la VM mapea el dominio a localhost.

**2. TLS Handshake (Puerto 443)**
```
Browser ←→ NGINX
  Client Hello (TLSv1.3, cipher suites)
  Server Hello (certificado, clave pública)
  Key Exchange
  Encrypted Session Established
```
NGINX presenta el certificado autofirmado generado en `nginx_start.sh`.

**3. Routing de NGINX**
```nginx
server {
    server_name jsagaro-.42.fr;
    
    location ~ \.php$ {
        fastcgi_pass wordpress:9000;  # ← Envía a contenedor WordPress
    }
}
```
NGINX determina qué contenedor debe manejar la petición basándose en `server_name`.

**4. FastCGI a PHP-FPM**
```
NGINX → wordpress:9000 (FastCGI protocol)
  SCRIPT_FILENAME=/var/www/html/index.php
  REQUEST_METHOD=GET
  ...
```
El protocolo FastCGI es binario y más eficiente que HTTP para comunicación local.

**5. WordPress Ejecuta PHP**
```php
// WordPress carga wp-config.php
define('DB_HOST', 'mariadb:3306');
define('WP_REDIS_HOST', 'redis');

// Intenta obtener página de Redis cache
$cached = wp_cache_get('front_page');
if (!$cached) {
    // Si no está en cache, consulta MariaDB
    $wpdb->get_results("SELECT * FROM wp_posts...");
}
```

**6. Respuesta**
```
MariaDB → WordPress → NGINX → Browser
  (datos)   (HTML)    (TLS)   (render)
```

### 2.2 Red Interna de Docker

```yaml
networks:
  jsagaro-net:
    driver: bridge
```

El driver `bridge` crea:
- Una interfaz virtual `docker0` en el host
- Una subred privada (típicamente `172.17.0.0/16`)
- DNS interno para resolución de nombres de contenedores

```
┌─────────────────────────────────────────────────────────────┐
│                      HOST VM                                │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              docker0 (bridge)                          │ │
│  │                172.17.0.1                              │ │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │ │
│  │  │  nginx   │ │wordpress │ │ mariadb  │ │  redis   │   │ │
│  │  │172.17.0.2│ │172.17.0.3│ │172.17.0.4│ │172.17.0.5│   │ │
│  │  │ eth0     │ │ eth0     │ │ eth0     │ │ eth0     │   │ │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘   │ │
│  └────────────────────────────────────────────────────────┘ │
│                           │                                 │
│                           │ NAT                             │
│                           ▼                                 │
│                    ┌──────────────┐                         │
│                    │   eth0 VM    │                         │
│                    │ 192.168.x.x  │                         │
│                    └──────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

#### DNS Interno de Docker

Docker Compose crea automáticamente entradas DNS para cada servicio:

```bash
# Desde el contenedor wordpress:
$ ping mariadb
PING mariadb (172.17.0.4): 56 data bytes
64 bytes from 172.17.0.4: seq=0 ttl=64 time=0.089 ms

$ ping redis
PING redis (172.17.0.5): 56 data bytes
```

Por eso en `wp-config.php` podemos usar `mariadb:3306` en lugar de una IP.

#### Exposición de Puertos

```yaml
nginx:
  ports:
    - "443:443"  # HOST:CONTAINER - Expuesto externamente

redis:
  expose:
    - "6379"     # Solo visible dentro de jsagaro-net
```

| Directiva | Visibilidad | Uso en Inception |
|-----------|-------------|------------------|
| `ports` | Host + Red Docker | Solo NGINX (443) y FTP (21) |
| `expose` | Solo Red Docker | Redis, Adminer, Static, Portainer |

### 2.3 Volúmenes y Persistencia

```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      device: /home/${USER}/data/mariadb
      o: bind
```

#### Anatomía de un Named Volume con Bind

| Opción | Significado |
|--------|-------------|
| `driver: local` | Usa el driver de almacenamiento local |
| `type: none` | No es un filesystem especial (no NFS, no tmpfs) |
| `device: /home/...` | Ruta en el host donde se almacenan los datos |
| `o: bind` | Monta directamente el directorio (como bind mount) |

**¿Por qué esta configuración híbrida?**

El subject dice:
- "You must use Docker named volumes" ✓
- "Both named volumes must store their data inside /home/login/data" ✓
- "Bind mounts are not allowed for these volumes" - Esta configuración usa **named volumes** con opción bind, no bind mounts directos

La diferencia:
```yaml
# BIND MOUNT DIRECTO (PROHIBIDO)
volumes:
  - /home/user/data/mariadb:/var/lib/mysql

# NAMED VOLUME CON BIND (PERMITIDO)
volumes:
  mariadb_data:
    driver_opts:
      device: /home/user/data/mariadb
      o: bind
```

El primero es un bind mount. El segundo es un named volume que internamente usa bind.

#### Persistencia de Datos

```
┌─────────────────────────────────────────────────────────────┐
│                    /home/jsagaro-/data/                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │  mariadb/   │  │  wordpress/ │  │  portainer/ │          │
│  │             │  │             │  │             │          │
│  │ ibdata1     │  │ wp-content/ │  │ portainer.db│          │
│  │ ib_logfile0 │  │ wp-config   │  │ certs/      │          │
│  │ wordpress/  │  │ index.php   │  │             │          │
│  │ (DB files)  │  │ (PHP files) │  │ (config)    │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
└─────────────────────────────────────────────────────────────┘
         ▲                 ▲                 ▲
         │                 │                 │
    ┌────┴────┐       ┌────┴────┐       ┌────┴────┐
    │ mariadb │       │wordpress│       │portainer│
    │   +     │       │   +     │       │         │
    │  ftp    │       │ nginx   │       │         │
    └─────────┘       └─────────┘       └─────────┘
```

Ciclo de vida:
1. `make all` → Crea directorios en host
2. Contenedores escriben datos
3. `make clean` → Contenedores eliminados, datos **persisten**
4. `make all` → Nuevos contenedores leen datos existentes
5. `make fclean` → Datos **eliminados** con `sudo rm -rf`

---

## 3. Disección del Código

### 3.1 NGINX: Configuración del Servidor

```nginx
# /etc/nginx/sites-available/default

# =====================================================
# Main server block: WordPress (jsagaro-.42.fr)
# =====================================================
server {
    listen 443 ssl;                    # 1
    listen [::]:443 ssl;               # 2

    server_name jsagaro-.42.fr;        # 3

    # SSL certs
    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;      # 4
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key; # 5
    ssl_protocols TLSv1.2 TLSv1.3;     # 6

    # WordPress root
    root /var/www/html;                # 7
    index index.php index.html index.htm;  # 8

    # Handle WordPress permalinks
    location / {                       # 9
        try_files $uri $uri/ /index.php$is_args$args;  # 10
    }

    # Pass PHP to WordPress container
    location ~ \.php$ {                # 11
        fastcgi_split_path_info ^(.+\.php)(/.+)$;      # 12
        fastcgi_pass wordpress:9000;   # 13
        fastcgi_index index.php;       # 14
        include fastcgi_params;        # 15
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;  # 16
        fastcgi_param PATH_INFO $fastcgi_path_info;    # 17
    }
}
```

#### Explicación Línea por Línea:

| Línea | Código | Explicación |
|-------|--------|-------------|
| 1 | `listen 443 ssl;` | Escucha en puerto 443 (HTTPS) con SSL habilitado para IPv4 |
| 2 | `listen [::]:443 ssl;` | Lo mismo para IPv6 |
| 3 | `server_name jsagaro-.42.fr;` | Este bloque solo responde a peticiones para este dominio |
| 4-5 | `ssl_certificate...` | Rutas al certificado y clave privada generados en el script de inicio |
| 6 | `ssl_protocols TLSv1.2 TLSv1.3;` | **CRÍTICO**: Solo acepta TLS 1.2 y 1.3 (requisito del subject) |
| 7 | `root /var/www/html;` | Directorio raíz del sitio (volumen compartido con WordPress) |
| 8 | `index index.php...` | Archivos a buscar cuando se pide un directorio |
| 9-10 | `location / { try_files... }` | Si el archivo no existe, redirige a `index.php` (WordPress routing) |
| 11 | `location ~ \.php$` | Regex: cualquier archivo terminado en `.php` |
| 12 | `fastcgi_split_path_info` | Separa la ruta del script de la información adicional |
| 13 | `fastcgi_pass wordpress:9000;` | Envía a PHP-FPM en el contenedor WordPress |
| 14 | `fastcgi_index index.php;` | Archivo por defecto para FastCGI |
| 15 | `include fastcgi_params;` | Incluye parámetros estándar de FastCGI |
| 16 | `SCRIPT_FILENAME` | Ruta completa al script PHP a ejecutar |
| 17 | `PATH_INFO` | Información adicional de la ruta |

### 3.2 FastCGI: Conexión NGINX-PHP

FastCGI es un protocolo binario para comunicación entre servidor web y aplicación.

```
┌─────────────────────────────────────────────────────────────┐
│                         NGINX                               │
│                                                             │
│  1. Recibe: GET /wp-admin/index.php HTTP/1.1                │
│                                                             │
│  2. Detecta: \.php$ → usar FastCGI                          │
│                                                             │
│  3. Construye mensaje FastCGI:                              │
│     ┌────────────────────────────────────────────────────┐  │
│     │ FCGI_BEGIN_REQUEST                                 │  │
│     │ FCGI_PARAMS:                                       │  │
│     │   SCRIPT_FILENAME=/var/www/html/wp-admin/index.php │  │
│     │   REQUEST_METHOD=GET                               │  │
│     │   QUERY_STRING=                                    │  │
│     │   CONTENT_TYPE=                                    │  │
│     │   CONTENT_LENGTH=0                                 │  │
│     │   SERVER_NAME=jsagaro-.42.fr                       │  │
│     │   ...                                              │  │
│     │ FCGI_STDIN (vacío para GET)                        │  │
│     └────────────────────────────────────────────────────┘  │
│                           │                                 │
│                           │ TCP :9000                       │
│                           ▼                                 │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      PHP-FPM                                │
│                                                             │
│  4. Recibe mensaje FastCGI                                  │
│                                                             │
│  5. Ejecuta: /var/www/html/wp-admin/index.php               │
│     - Carga wp-config.php                                   │
│     - Conecta a MariaDB                                     │
│     - Genera HTML                                           │
│                                                             │
│  6. Responde:                                               │
│     ┌────────────────────────────────────────────────────┐  │
│     │ FCGI_STDOUT:                                       │  │
│     │   Status: 200 OK                                   │  │
│     │   Content-Type: text/html                          │  │
│     │                                                    │  │
│     │   <!DOCTYPE html><html>...</html>                  │  │
│     │ FCGI_END_REQUEST                                   │  │
│     └────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

#### Configuración de PHP-FPM (www.conf)

```ini
[www]
user = www-data                 # Usuario que ejecuta PHP
group = www-data                # Grupo
listen = 0.0.0.0:9000          # Escucha en todas las interfaces, puerto 9000
pm = dynamic                    # Gestión dinámica de procesos worker
pm.max_children = 5             # Máximo 5 procesos hijo
pm.start_servers = 2            # Iniciar con 2 procesos
pm.min_spare_servers = 1        # Mínimo 1 proceso en espera
pm.max_spare_servers = 3        # Máximo 3 procesos en espera
clear_env = no                  # NO limpiar variables de entorno (necesario para Docker)
```

`clear_env = no` es crucial: permite que las variables de entorno de Docker (como las de `.env`) sean visibles para PHP.

### 3.3 WordPress: Script de Inicialización

```bash
#!/bin/bash

# 1. Read passwords from Docker Secrets
DB_PASS=$(cat /run/secrets/db_password)           # 1
WP_ADMIN_PASS=$(cat /run/secrets/wp_admin_password)
WP_USER_PASS=$(cat /run/secrets/wp_user_password)

# First-time setup if wp-config.php doesn't exist
if [ ! -f wp-config.php ]; then                   # 2
    echo "Configurando WordPress por primera vez..."

    # Download WordPress core
    wp core download --locale=es_ES --allow-root  # 3

    # Create wp-config.php
    wp config create \                            # 4
        --dbname=${SQL_DATABASE} \
        --dbuser=${SQL_USER} \
        --dbpass=${DB_PASS} \
        --dbhost=mariadb:3306 \
        --allow-root

    # Add Redis config BEFORE install
    wp config set WP_REDIS_HOST "${WP_REDIS_HOST}" --allow-root  # 5
    wp config set WP_REDIS_PORT "${WP_REDIS_PORT}" --allow-root
    wp config set WP_CACHE true --raw --allow-root

    # Install WordPress (creates tables + admin user)
    wp core install \                             # 6
        --url=https://${DOMAIN_NAME} \
        --title="Inception 42" \
        --admin_user=${WP_ADMIN_USER} \
        --admin_password=${WP_ADMIN_PASS} \
        --admin_email=${WP_ADMIN_EMAIL} \
        --allow-root

    # Create additional user (required by subject)
    wp user create \                              # 7
        ${WP_USER} \
        ${WP_USER_EMAIL} \
        --role=author \
        --user_pass=${WP_USER_PASS} \
        --allow-root

    # Setup Redis Object Cache plugin
    wp plugin install redis-cache --activate --allow-root  # 8
    wp redis enable --allow-root

    echo "Redis Object Cache configurado correctamente."
else
    echo "WordPress ya está configurado. Saltando instalación."
fi

# Fix permissions for NGINX/PHP-FPM
chown -R www-data:www-data /var/www/html         # 9

# Start PHP-FPM in foreground (PID 1)
exec php-fpm8.2 -F                               # 10
```

#### Análisis Detallado:

| # | Código | Propósito |
|---|--------|-----------|
| 1 | `$(cat /run/secrets/...)` | Lee contraseñas de Docker Secrets (montados como archivos) |
| 2 | `if [ ! -f wp-config.php ]` | Idempotencia: solo configura si es la primera vez |
| 3 | `wp core download` | Descarga WordPress desde wordpress.org |
| 4 | `wp config create` | Genera `wp-config.php` con credenciales de BD |
| 5 | `wp config set WP_REDIS_*` | Añade configuración de Redis para caching |
| 6 | `wp core install` | Crea tablas en MariaDB, usuario admin |
| 7 | `wp user create` | Crea segundo usuario (requisito del subject) |
| 8 | `wp plugin install redis-cache` | Instala y activa plugin de cache |
| 9 | `chown -R www-data:www-data` | PHP-FPM corre como www-data, necesita permisos |
| 10 | `exec php-fpm8.2 -F` | `-F`: foreground. `exec`: reemplaza bash, PID 1 |

#### Flujo de Docker Secrets

```
┌─────────────────────────────────────────────────────────────┐
│                       HOST                                  │
│  secrets/                                                   │
│    ├── db_password.txt        (contiene: "mi_password")     │
│    ├── wp_admin_password.txt                                │
│    └── ...                                                  │
└─────────────────────────────────────────────────────────────┘
                    │
                    │ docker-compose.yml:
                    │   secrets:
                    │     db_password:
                    │       file: ../secrets/db_password.txt
                    ▼
┌─────────────────────────────────────────────────────────────┐
│                 CONTENEDOR WORDPRESS                        │
│  /run/secrets/                                              │
│    ├── db_password        (archivo, solo lectura)           │
│    ├── wp_admin_password                                    │
│    └── ...                                                  │
│                                                             │
│  $ cat /run/secrets/db_password                             │
│  mi_password                                                │
└─────────────────────────────────────────────────────────────┘
```

Docker monta los secrets como archivos en `/run/secrets/` con permisos 0400 (solo lectura por root).

### 3.4 MariaDB: Inicialización Segura

```bash
#!/bin/bash

# 1. Read passwords from Docker Secrets
DB_PASS=$(cat /run/secrets/db_password)
DB_ROOT_PASS=$(cat /run/secrets/db_root_password)

# 2. Create temp SQL init file
cat << EOF > /tmp/init.sql
CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;
CREATE USER IF NOT EXISTS \`${SQL_USER}\`@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO \`${SQL_USER}\`@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
FLUSH PRIVILEGES;
EOF

# 3. Start MariaDB with init file (keeps PID 1)
exec mysqld_safe --init-file=/tmp/init.sql
```

#### SQL de Inicialización:

```sql
-- Crea la base de datos si no existe
CREATE DATABASE IF NOT EXISTS `wordpress`;

-- Crea usuario para WordPress (% = cualquier host)
CREATE USER IF NOT EXISTS `jsagaro-`@'%' IDENTIFIED BY 'password_del_secret';

-- Otorga todos los privilegios sobre wordpress.* al usuario
GRANT ALL PRIVILEGES ON `wordpress`.* TO `jsagaro-`@'%';

-- Cambia la contraseña de root
ALTER USER 'root'@'localhost' IDENTIFIED BY 'root_password_del_secret';

-- Recarga privilegios
FLUSH PRIVILEGES;
```

**¿Por qué `@'%'`?**

El `%` es un wildcard que permite conexiones desde cualquier host. Necesario porque WordPress se conecta desde otro contenedor (IP dinámica en la red Docker).

### 3.5 Docker Compose: Orquestación

```yaml
services:
  nginx:
    container_name: nginx           # 1
    build: ./requirements/nginx     # 2
    image: nginx_image              # 3
    restart: always                 # 4
    env_file: .env                  # 5
    ports:
      - "443:443"                   # 6
    depends_on:
      - wordpress                   # 7
    networks:
      - jsagaro-net                 # 8
    volumes:
      - wordpress_data:/var/www/html  # 9
```

| # | Directiva | Explicación |
|---|-----------|-------------|
| 1 | `container_name` | Nombre fijo del contenedor (también hostname en la red) |
| 2 | `build` | Ruta al directorio con el Dockerfile |
| 3 | `image` | Nombre de la imagen resultante |
| 4 | `restart: always` | Si el contenedor crashea, Docker lo reinicia automáticamente |
| 5 | `env_file` | Carga variables de entorno desde `.env` |
| 6 | `ports: "443:443"` | Mapea puerto 443 del host al 443 del contenedor |
| 7 | `depends_on` | NGINX espera a que WordPress inicie (no garantiza que esté "listo") |
| 8 | `networks` | Conecta a la red `jsagaro-net` |
| 9 | `volumes` | Monta el volumen `wordpress_data` |

#### Orden de Arranque

```
1. mariadb    ─┐
               ├──▶ 2. redis ─┐
               │              ├──▶ 3. wordpress ──▶ 4. nginx
               │              │
               └──────────────┘
               
   adminer (depends_on: mariadb)
   ftp (depends_on: wordpress)
   static, portainer (independientes)
```

**Nota**: `depends_on` solo espera a que el contenedor **inicie**, no a que el servicio esté listo. Por eso WordPress tiene un retry loop implícito al conectar a MariaDB.

---

## 4. Glosario de Comandos y Flags

### 4.1 Flags de Dockerfiles

#### Comando `RUN apt-get`

```dockerfile
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*
```

| Componente | Significado |
|------------|-------------|
| `apt-get update` | Actualiza la lista de paquetes disponibles |
| `&&` | Encadena comandos (el siguiente solo se ejecuta si el anterior tuvo éxito) |
| `apt-get install -y` | `-y`: Responde "yes" automáticamente a todas las preguntas |
| `\` | Continúa el comando en la siguiente línea |
| `rm -rf /var/lib/apt/lists/*` | Limpia cache de apt para reducir tamaño de imagen |

#### Comando `nginx`

```bash
exec nginx -g "daemon off;"
```

| Flag | Significado |
|------|-------------|
| `-g "daemon off;"` | Directiva global: no demonizar (correr en foreground) |

Sin `daemon off`, nginx haría fork y el proceso padre terminaría, matando el contenedor.

#### Comando `php-fpm`

```bash
exec php-fpm8.2 -F
```

| Flag | Significado |
|------|-------------|
| `-F` | Force foreground (no demonizar) |

#### Comando `mysqld_safe`

```bash
exec mysqld_safe --init-file=/tmp/init.sql
```

| Flag | Significado |
|------|-------------|
| `--init-file=...` | Ejecuta el SQL de este archivo al iniciar |

`mysqld_safe` es un wrapper que monitorea `mysqld` y lo reinicia si crashea. También ya corre en foreground.

#### Comando `redis-server`

```bash
exec redis-server /etc/redis/redis.conf
```

El archivo de configuración incluye `daemonize no` para foreground.

#### Comando `openssl` (generación de certificado)

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=42/OU=jsagaro-/CN=${DOMAIN_NAME}" \
    -addext "subjectAltName=DNS:${DOMAIN_NAME},DNS:adminer.${DOMAIN_NAME},..."
```

| Flag | Significado |
|------|-------------|
| `req` | Solicitud de certificado |
| `-x509` | Genera certificado autofirmado (no CSR) |
| `-nodes` | No cifrar la clave privada con passphrase |
| `-days 365` | Validez del certificado |
| `-newkey rsa:2048` | Genera nueva clave RSA de 2048 bits |
| `-keyout` | Ruta para guardar la clave privada |
| `-out` | Ruta para guardar el certificado |
| `-subj` | Subject del certificado (sin prompt interactivo) |
| `-addext "subjectAltName=..."` | Subject Alternative Names (para múltiples dominios) |

### 4.2 Comandos del Makefile

```makefile
all:
    @docker compose -f $(COMPOSE_FILE) up -d --build
```

| Componente | Significado |
|------------|-------------|
| `@` | Silencia el echo del comando |
| `docker compose` | Nueva sintaxis (vs `docker-compose`) |
| `-f $(COMPOSE_FILE)` | Especifica archivo compose |
| `up` | Crea e inicia contenedores |
| `-d` | Detached (background) |
| `--build` | Reconstruye imágenes antes de iniciar |

```makefile
fclean:
    @docker compose -f $(COMPOSE_FILE) down -v --rmi all
```

| Flag | Significado |
|------|-------------|
| `down` | Detiene y elimina contenedores, redes |
| `-v` | También elimina volúmenes |
| `--rmi all` | Elimina todas las imágenes usadas |

### 4.3 Comandos de Servicios

#### WP-CLI

```bash
wp core download --locale=es_ES --allow-root
```

| Flag | Significado |
|------|-------------|
| `--locale=es_ES` | Descarga WordPress en español |
| `--allow-root` | Permite ejecutar como root (necesario en Docker) |

```bash
wp config set WP_CACHE true --raw --allow-root
```

| Flag | Significado |
|------|-------------|
| `--raw` | Inserta valor sin comillas (booleano, no string) |

#### vsftpd (FTP)

```bash
exec vsftpd /etc/vsftpd.conf
```

Configuración clave en `vsftpd.conf`:

| Directiva | Valor | Significado |
|-----------|-------|-------------|
| `background=NO` | | No demonizar (foreground para Docker) |
| `anonymous_enable=NO` | | Deshabilita usuarios anónimos |
| `local_enable=YES` | | Permite usuarios del sistema |
| `chroot_local_user=YES` | | Encierra usuarios en su home (chroot jail) |
| `pasv_enable=YES` | | Habilita modo pasivo |
| `pasv_min_port=21100` | | Rango de puertos para modo pasivo |
| `pasv_max_port=21110` | | (deben estar expuestos en docker-compose) |

---

## 5. Simulación de Defensa: 10 Preguntas Difíciles

### Pregunta 1: ¿Por qué no usas `docker run` directamente?

**Respuesta ideal:**

Docker Compose es la herramienta para orquestar múltiples contenedores. Mientras `docker run` inicia un solo contenedor, `docker compose` permite:

1. **Definir infraestructura como código**: Todo en `docker-compose.yml`
2. **Gestionar dependencias**: `depends_on` controla orden de arranque
3. **Redes automáticas**: Crea red bridge y DNS interno
4. **Volúmenes nombrados**: Persistencia declarativa
5. **Comandos unificados**: `docker compose up/down` gestiona todo el stack

Si usara `docker run`, tendría que:
```bash
docker network create jsagaro-net
docker volume create mariadb_data
docker run -d --name mariadb --network jsagaro-net -v mariadb_data:/var/lib/mysql ...
docker run -d --name wordpress --network jsagaro-net --depends... 
# etc, muy propenso a errores
```

---

### Pregunta 2: ¿Qué pasaría si quitas `exec` del script de NGINX?

**Respuesta ideal:**

Sin `exec`, la jerarquía de procesos sería:

```
PID 1: /bin/bash (nginx_start.sh)
  └── PID 2: nginx master process
        ├── PID 3: nginx worker
        └── PID 4: nginx worker
```

Problemas:
1. **Señales no propagadas**: Cuando Docker envía `SIGTERM`, bash lo recibe pero no lo reenvía a nginx
2. **Shutdown no graceful**: Docker espera 10 segundos y envía `SIGKILL`
3. **Conexiones cortadas abruptamente**: Los clientes ven errores
4. **Posible corrupción**: Si nginx estaba escribiendo logs

Con `exec`, nginx reemplaza bash y recibe las señales directamente:
```
PID 1: nginx master process
  ├── PID 2: nginx worker
  └── PID 3: nginx worker
```

---

### Pregunta 3: Explica la diferencia entre `ports` y `expose`

**Respuesta ideal:**

```yaml
nginx:
  ports:
    - "443:443"    # HOST:CONTAINER

redis:
  expose:
    - "6379"
```

| Directiva | Accesible desde | Caso de uso |
|-----------|-----------------|-------------|
| `ports` | Host + otros contenedores | NGINX (entrada externa), FTP |
| `expose` | Solo otros contenedores | Redis, Adminer, Portainer (solo interno) |

`ports: "443:443"` significa:
- El puerto 443 del HOST se mapea al 443 del CONTENEDOR
- Cualquiera puede acceder desde fuera de Docker

`expose: "6379"` significa:
- El puerto 6379 es accesible dentro de la red Docker
- NO se mapea a ningún puerto del host
- Es documentación (los puertos ya están "expuestos" internamente)

Esto cumple el requisito: "NGINX must be the only entrypoint via port 443"

---

### Pregunta 4: ¿Por qué el admin no puede llamarse "admin"?

**Respuesta ideal:**

Es un requisito de seguridad del subject:

> "The administrator's username can't contain admin/Admin or administrator/Administrator"

Razones de seguridad:
1. **Ataques de fuerza bruta**: "admin" es el primer username que prueban los bots
2. **Enumeración de usuarios**: WordPress revela si un usuario existe al intentar login
3. **Defensa en profundidad**: Incluso con contraseña fuerte, username predecible es vector de ataque

En mi proyecto uso `jsagaro-boss` que no contiene "admin" en ninguna forma.

---

### Pregunta 5: ¿Cómo funcionan los Docker Secrets y por qué no usar variables de entorno?

**Respuesta ideal:**

**Variables de entorno (inseguras):**
```yaml
environment:
  - DB_PASSWORD=mi_password_secreta
```

Problemas:
1. Visibles con `docker inspect container_name`
2. Visibles en `/proc/<pid>/environ` dentro del contenedor
3. Pueden filtrarse en logs de aplicación
4. Heredadas por procesos hijo

**Docker Secrets (seguras):**
```yaml
secrets:
  - db_password

secrets:
  db_password:
    file: ../secrets/db_password.txt
```

Ventajas:
1. Montados en `/run/secrets/` como archivos con permisos 0400
2. Solo accesibles por root dentro del contenedor
3. No aparecen en `docker inspect`
4. En memoria (tmpfs), no en disco del contenedor
5. Los archivos fuente están en `.gitignore`

El subject exige: "It is mandatory to use Docker secrets to store any confidential information"

---

### Pregunta 6: ¿Qué significa `restart: always` y cuándo se activa?

**Respuesta ideal:**

```yaml
mariadb:
  restart: always
```

Políticas de reinicio:

| Política | Comportamiento |
|----------|----------------|
| `no` | Nunca reinicia (default) |
| `always` | Siempre reinicia, incluso si sale con código 0 |
| `on-failure` | Solo reinicia si sale con código != 0 |
| `unless-stopped` | Como `always`, pero no reinicia si fue detenido manualmente |

`always` se activa cuando:
1. El proceso principal termina (cualquier exit code)
2. Docker daemon reinicia
3. La VM se reinicia

**No** se activa cuando:
1. Se usa `docker stop` o `docker compose down`
2. Se elimina el contenedor

El subject exige: "Your containers have to restart in case of a crash"

---

### Pregunta 7: ¿Por qué usas `debian:bookworm` y no `debian:latest`?

**Respuesta ideal:**

El subject prohíbe explícitamente `latest`:

> "The latest tag is prohibited"

Razones técnicas:
1. **Reproducibilidad**: `latest` cambia con cada nueva release de Debian
2. **Builds no deterministas**: Hoy funciona, mañana falla por actualización
3. **Seguridad**: No puedes auditar qué versión exacta tienes
4. **CI/CD**: Los pipelines pueden romperse sin cambios en tu código

`debian:bookworm` es:
- Debian 12 (stable)
- La "penultimate stable version" que permite el subject
- Versión fija que no cambia hasta que yo la actualice

---

### Pregunta 8: Explica qué hace `fastcgi_pass wordpress:9000`

**Respuesta ideal:**

```nginx
location ~ \.php$ {
    fastcgi_pass wordpress:9000;
    ...
}
```

Desglose:

1. **`location ~ \.php$`**: Regex que captura cualquier URL terminada en `.php`

2. **`fastcgi_pass`**: Indica que esta petición se reenviará usando protocolo FastCGI (no HTTP)

3. **`wordpress`**: Hostname del contenedor WordPress (resuelto por DNS interno de Docker a su IP)

4. **`:9000`**: Puerto donde PHP-FPM escucha conexiones FastCGI

Flujo completo:
```
Browser → NGINX:443 → FastCGI → wordpress:9000 (PHP-FPM) → ejecuta PHP → respuesta
```

PHP-FPM (FastCGI Process Manager) es el servidor que:
- Recibe peticiones FastCGI
- Gestiona un pool de workers PHP
- Ejecuta los scripts PHP
- Devuelve el output (HTML) a NGINX

---

### Pregunta 9: ¿Qué son los namespaces de Linux y cuáles usa Docker?

**Respuesta ideal:**

Los namespaces son una característica del kernel Linux que proporciona aislamiento de recursos del sistema. Docker usa 6 tipos:

| Namespace | Aísla | Ejemplo en Inception |
|-----------|-------|---------------------|
| **PID** | IDs de proceso | Cada contenedor ve su propio PID 1 |
| **NET** | Stack de red | Cada contenedor tiene su propia IP en 172.17.x.x |
| **MNT** | Puntos de montaje | WordPress ve `/var/www/html`, no el FS del host |
| **UTS** | Hostname | `container_name: nginx` establece hostname |
| **IPC** | Comunicación entre procesos | Memoria compartida aislada |
| **USER** | UIDs/GIDs | `www-data` en contenedor != `www-data` en host |

Verificación práctica:
```bash
# En el host
$ ls /proc/self/ns/
cgroup  ipc  mnt  net  pid  pid_for_children  user  uts

# Comparar con un contenedor
$ docker exec nginx ls /proc/self/ns/
# Los IDs de namespace serán diferentes
```

---

### Pregunta 10: Si MariaDB tarda en iniciar, ¿WordPress falla?

**Respuesta ideal:**

`depends_on` solo garantiza **orden de inicio**, no que el servicio esté **listo**:

```yaml
wordpress:
  depends_on:
    - mariadb
```

Esto significa:
- Docker inicia MariaDB **antes** de WordPress
- **No** espera a que MariaDB acepte conexiones

**¿Por qué no falla WordPress?**

1. **Retry implícito de WP-CLI**: `wp config create` intenta conectar a MariaDB y falla si no está listo, pero el script puede reintentar.

2. **`restart: always`**: Si WordPress falla al conectar, el contenedor se reinicia y vuelve a intentar.

3. **MariaDB es rápido**: Típicamente MariaDB está listo en 2-3 segundos, WordPress tarda más en descargar archivos.

Solución robusta (no implementada pero válida para discutir):
```yaml
wordpress:
  depends_on:
    mariadb:
      condition: service_healthy

mariadb:
  healthcheck:
    test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
    interval: 5s
    timeout: 3s
    retries: 5
```

---

## Resumen de Checklist de Evaluación

| Requisito | Estado | Evidencia |
|-----------|--------|-----------|
| VM con Docker | ✓ | Proyecto diseñado para VM Debian |
| Archivos en `srcs/` | ✓ | `srcs/docker-compose.yml`, `srcs/requirements/` |
| Makefile en raíz | ✓ | `Makefile` con targets all, clean, fclean, re |
| Dockerfiles propios | ✓ | 8 Dockerfiles (3 mandatory + 5 bonus) |
| Base debian:bookworm | ✓ | Todos los Dockerfiles |
| Sin tag `latest` | ✓ | Verificado con grep |
| Sin contraseñas en Dockerfile | ✓ | Usan Docker Secrets |
| NGINX solo puerto 443 | ✓ | `ports: "443:443"`, otros usan `expose` |
| TLSv1.2/1.3 | ✓ | `ssl_protocols TLSv1.2 TLSv1.3;` |
| WordPress + PHP-FPM | ✓ | Sin nginx en contenedor WordPress |
| MariaDB sin nginx | ✓ | Solo mariadb-server |
| Dos usuarios WP | ✓ | `jsagaro-boss` (admin) + `jsagaro-user` |
| Admin sin "admin" | ✓ | `jsagaro-boss` |
| Named volumes | ✓ | `mariadb_data`, `wordpress_data`, `portainer_data` |
| Datos en /home/login/data | ✓ | `device: /home/${USER}/data/...` |
| Red Docker bridge | ✓ | `jsagaro-net: driver: bridge` |
| Sin network:host/--link | ✓ | Verificado con grep |
| restart: always | ✓ | Todos los servicios |
| Sin hacky patches | ✓ | Todos usan `exec`, sin tail -f/sleep |
| PID 1 correcto | ✓ | `exec` en todos los scripts |
| .env para config | ✓ | `srcs/.env` |
| Secrets para passwords | ✓ | 5 archivos en `secrets/` |
| Bonus: Redis | ✓ | Cache para WordPress |
| Bonus: FTP | ✓ | vsftpd apuntando a wordpress_data |
| Bonus: Adminer | ✓ | UI para MariaDB |
| Bonus: Static | ✓ | Portfolio HTML/CSS/JS (no PHP) |
| Bonus: Servicio extra | ✓ | Portainer (gestión Docker) |

---

*Documento generado para preparación de defensa - Inception 42*
