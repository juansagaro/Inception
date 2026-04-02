# Developer Documentation

Technical guide for developers maintaining or extending the Inception infrastructure.

---

## Prerequisites

### System Requirements

- **Operating System:** Linux (Debian/Ubuntu recommended) or macOS
- **Virtual Machine:** Required by 42 subject - use VirtualBox, UTM, or VMware
- **Docker:** Version 20.10+ with Docker Compose V2
- **RAM:** Minimum 4GB allocated to VM
- **Disk:** Minimum 10GB free space

### Install Docker (Debian/Ubuntu)

```bash
# Remove old versions
sudo apt-get remove docker docker-engine docker.io containerd runc

# Install dependencies
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg

# Add Docker GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group (logout required)
sudo usermod -aG docker $USER
```

### Configure Domain

Add to `/etc/hosts`:

```
127.0.0.1 jsagaro-.42.fr
127.0.0.1 adminer.jsagaro-.42.fr
127.0.0.1 static.jsagaro-.42.fr
127.0.0.1 portainer.jsagaro-.42.fr
```

---

## Environment Setup

### Directory Structure

```
Inception/
├── Makefile                 # Build orchestration
├── docs/                    # Documentation
│   ├── README.md
│   ├── USER_DOC.md
│   └── DEV_DOC.md
├── secrets/                 # Docker secrets (git-ignored)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   ├── wp_user_password.txt
│   └── ftp_password.txt
└── srcs/
    ├── .env                 # Environment variables
    ├── docker-compose.yml   # Service definitions
    └── requirements/        # Dockerfiles and configs
        ├── nginx/
        ├── mariadb/
        ├── wordpress/
        └── bonus/
            ├── redis/
            ├── adminer/
            ├── static/
            ├── ftp/
            └── portainer/
```

### Environment Variables (`srcs/.env`)

```bash
# Domain Configuration
DOMAIN_NAME=jsagaro-.42.fr

# MariaDB Configuration
SQL_DATABASE=wordpress
SQL_USER=jsagaro-

# WordPress Configuration
WP_TITLE=Inception_42
WP_ADMIN_USER=jsagaro-boss
WP_ADMIN_EMAIL=jsagaro-@student.42madrid.com
WP_USER=jsagaro-user
WP_USER_EMAIL=jsagaro-@gmail.com

# Redis Configuration (Bonus)
WP_REDIS_HOST=redis
WP_REDIS_PORT=6379

# FTP Configuration (Bonus)
FTP_USER=ftpuser
```

### Secrets Setup

Create the `secrets/` directory and populate each file with a secure password:

```bash
mkdir -p secrets
echo "your_db_password" > secrets/db_password.txt
echo "your_db_root_password" > secrets/db_root_password.txt
echo "your_wp_admin_password" > secrets/wp_admin_password.txt
echo "your_wp_user_password" > secrets/wp_user_password.txt
echo "your_ftp_password" > secrets/ftp_password.txt
```

**Security Note:** These files must be in `.gitignore` and never committed.

---

## Build and Launch

### Makefile Targets

| Command | Description |
|---------|-------------|
| `make all` | Build images and start all containers |
| `make clean` | Stop and remove containers (preserves data) |
| `make fclean` | Full cleanup: containers, images, volumes, data |
| `make re` | Equivalent to `fclean` + `all` |
| `make stop` | Pause containers without removing |
| `make start` | Resume paused containers |
| `make status` | Show container status |
| `make logs` | Stream real-time logs |

### Build Process

```bash
# First-time setup
make all
```

This executes:
1. Creates `/home/$USER/data/{mariadb,wordpress,portainer}` directories
2. Runs `docker compose -f srcs/docker-compose.yml up -d --build`
3. Builds all 8 custom Docker images
4. Starts containers with proper dependency order

### Verify Build

```bash
# Check all containers are running
make status

# View build logs
docker compose -f srcs/docker-compose.yml logs --tail=50
```

---

## Docker Commands Reference

### Container Management

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Enter container shell
docker exec -it nginx /bin/sh
docker exec -it wordpress /bin/bash
docker exec -it mariadb /bin/bash

# Restart specific container
docker restart nginx

# View container logs
docker logs -f wordpress --tail=100
```

### Image Management

```bash
# List project images
docker images | grep _image

# Rebuild specific image
docker compose -f srcs/docker-compose.yml build nginx

# Remove unused images
docker image prune -a
```

### Network Management

```bash
# List networks
docker network ls

# Inspect project network
docker network inspect srcs_jsagaro-net

# Check container connectivity
docker exec nginx ping wordpress
docker exec wordpress ping mariadb
```

### Volume Management

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect srcs_wordpress_data

# Check volume mount points
docker inspect wordpress --format '{{ range .Mounts }}{{ .Source }} -> {{ .Destination }}{{ end }}'
```

---

## Data Persistence

### Host Storage Location

All persistent data is stored in `/home/$USER/data/`:

```
/home/jsagaro-/data/
├── mariadb/      # Database files
├── wordpress/    # WordPress core, plugins, themes, uploads
└── portainer/    # Portainer configuration
```

### Volume Configuration

Defined in `docker-compose.yml`:

```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      device: /home/${USER}/data/mariadb
      o: bind
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      device: /home/${USER}/data/wordpress
      o: bind
  portainer_data:
    driver: local
    driver_opts:
      type: none
      device: /home/${USER}/data/portainer
      o: bind
```

### How Persistence Works

1. **Named volumes** with `local` driver and `bind` option
2. Data physically stored on host at `/home/$USER/data/`
3. Survives `docker compose down` and container recreation
4. Only deleted with `make fclean` or manual `rm -rf`

### Backup Recommendations

```bash
# Backup all data
sudo tar -czvf inception_backup_$(date +%Y%m%d).tar.gz /home/$USER/data/

# Backup database only
docker exec mariadb mysqldump -u root -p$DB_ROOT_PASS wordpress > backup.sql
```

---

## Architecture Overview

### Service Dependencies

```
                    ┌─────────────┐
                    │   NGINX     │ :443
                    │ (TLS Proxy) │
                    └──────┬──────┘
                           │
       ┌───────────┬───────┼───────┬───────────┐
       │           │       │       │           │
       ▼           ▼       ▼       ▼           ▼
┌──────────┐ ┌─────────┐ ┌──────┐ ┌─────────┐ ┌──────┐
│ Adminer  │ │WordPress│ │Static│ │Portainer│ │ FTP  │
│  :8080   │ │  :9000  │ │ :80  │ │  :9000  │ │ :21  │
└────┬─────┘ └────┬────┘ └──────┘ └─────────┘ └──┬───┘
     │            │                              │
     │      ┌─────┴─────┐                        │
     │      │           │                        │
     ▼      ▼           ▼                        │
┌──────────────┐   ┌─────────┐                   │
│   MariaDB    │   │  Redis  │                   │
│    :3306     │   │  :6379  │                   │
└──────────────┘   └─────────┘                   │
     ▲                                           │
     │              wordpress_data               │
     └───────────────────────────────────────────┘
```

### Network Topology

- **Network:** `jsagaro-net` (bridge driver)
- **External access:** Only NGINX on port 443
- **Internal communication:** Containers use service names as hostnames

### Container Base Images

All containers built from `debian:bookworm`:

| Service | Base | Key Packages |
|---------|------|--------------|
| NGINX | debian:bookworm | nginx, openssl |
| WordPress | debian:bookworm | php-fpm, wp-cli |
| MariaDB | debian:bookworm | mariadb-server |
| Redis | debian:bookworm | redis-server |
| Adminer | debian:bookworm | php, adminer |
| Static | debian:bookworm | nginx |
| FTP | debian:bookworm | vsftpd |
| Portainer | debian:bookworm | portainer binary |

---

## Extending the Infrastructure

### Adding a New Service

1. Create directory: `srcs/requirements/bonus/newservice/`
2. Create `Dockerfile` (base: `debian:bookworm`)
3. Create `tools/newservice_start.sh` with `exec` for PID 1
4. Add service to `docker-compose.yml`
5. Add NGINX location block if web-accessible

### Dockerfile Requirements (42 Subject)

- Base image: `debian:bookworm` or `alpine` (penultimate stable)
- No `latest` tag
- No passwords in Dockerfile
- Use environment variables and secrets
- Entry script must use `exec` (PID 1)
- No hacky patches: `tail -f`, `sleep infinity`, `while true`

---

## Debugging

### Common Issues

**Container exits immediately:**
```bash
docker logs <container_name>
# Check if exec is used in entrypoint
```

**Network connectivity:**
```bash
docker exec nginx ping mariadb
docker exec wordpress nc -zv mariadb 3306
```

**Permission issues:**
```bash
# Check volume ownership
ls -la /home/$USER/data/
sudo chown -R 1000:1000 /home/$USER/data/wordpress
```

**WordPress can't connect to database:**
```bash
# Verify MariaDB is ready
docker exec mariadb mysqladmin -u root -p ping
# Check credentials match
docker exec wordpress cat /run/secrets/db_password
```
