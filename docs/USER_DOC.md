# User Documentation

This guide explains how to use the Inception infrastructure as an end-user or administrator.

---

## Services Overview

This stack provides a complete web hosting infrastructure:

| Service | Description | Access |
|---------|-------------|--------|
| **NGINX** | Reverse proxy and TLS termination | Port 443 (HTTPS only) |
| **WordPress** | Content management system | `https://jsagaro-.42.fr` |
| **MariaDB** | Database server for WordPress | Internal only |
| **Redis** | Cache system for WordPress performance | Internal only |
| **Adminer** | Web-based database management | `https://jsagaro-.42.fr/adminer` |
| **FTP** | File transfer to WordPress files | Port 21 |
| **Portainer** | Docker container management UI | `https://jsagaro-.42.fr/portainer` |
| **Static Site** | Personal portfolio website | `https://jsagaro-.42.fr/static` |

---

## Starting the Project

Open a terminal in the project root directory and run:

```bash
make all
```

This command will:
1. Create necessary data directories in `/home/jsagaro-/data/`
2. Build all Docker images from scratch
3. Start all containers in the background

Wait approximately 1-2 minutes for all services to initialize.

---

## Stopping the Project

### Pause (keep data intact)

```bash
make stop
```

Containers stop but retain their state. Resume with `make start`.

### Stop and remove containers

```bash
make clean
```

Containers are removed, but all data (database, WordPress files) is preserved.

### Full reset (delete everything)

```bash
make fclean
```

**Warning:** This removes all containers, images, volumes, and data. Use only when you want a fresh start.

---

## Accessing the Website

### WordPress Site

- **URL:** `https://jsagaro-.42.fr`
- **Note:** Your browser will show a security warning because the TLS certificate is self-signed. This is expected - click "Advanced" and proceed.

### WordPress Admin Panel

- **URL:** `https://jsagaro-.42.fr/wp-admin`
- **Admin username:** `jsagaro-boss`
- **Admin password:** Located in `secrets/wp_admin_password.txt`

### Other Services

| Service | URL |
|---------|-----|
| Adminer (Database UI) | `https://jsagaro-.42.fr/adminer` |
| Portainer (Docker UI) | `https://jsagaro-.42.fr/portainer` |
| Static Portfolio | `https://jsagaro-.42.fr/static` |

---

## Credential Management

### Environment Variables (`.env`)

Located at `srcs/.env`, this file contains non-sensitive configuration:

| Variable | Purpose |
|----------|---------|
| `DOMAIN_NAME` | Your domain (jsagaro-.42.fr) |
| `SQL_DATABASE` | Database name |
| `SQL_USER` | Database username |
| `WP_TITLE` | WordPress site title |
| `WP_ADMIN_USER` | WordPress admin username |
| `WP_ADMIN_EMAIL` | WordPress admin email |
| `WP_USER` | WordPress regular user |
| `FTP_USER` | FTP username |

### Secrets (passwords)

Located in the `secrets/` directory at the project root:

| File | Contains |
|------|----------|
| `db_password.txt` | MariaDB user password |
| `db_root_password.txt` | MariaDB root password |
| `wp_admin_password.txt` | WordPress admin password |
| `wp_user_password.txt` | WordPress regular user password |
| `ftp_password.txt` | FTP user password |

**Important:** These files are excluded from Git for security. Never share them.

---

## Checking Service Health

### Quick status check

```bash
make status
```

All containers should show `Up` status.

### Expected output

```
NAME        STATUS
nginx       Up
wordpress   Up
mariadb     Up
redis       Up
adminer     Up
static      Up
ftp         Up
portainer   Up
```

### View real-time logs

```bash
make logs
```

Press `Ctrl+C` to exit log view.

### Check individual service

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### Verify website is responding

```bash
curl -k https://jsagaro-.42.fr
```

You should receive HTML content (not an error).

---

## Troubleshooting

### "Connection refused" error

- Ensure containers are running: `make status`
- Check if port 443 is available: `sudo lsof -i :443`

### "This site can't be reached"

- Verify `/etc/hosts` contains: `127.0.0.1 jsagaro-.42.fr`
- Restart NGINX: `docker restart nginx`

### Database connection error in WordPress

- Check MariaDB is running: `docker logs mariadb`
- Verify credentials match between `.env` and `secrets/`

### Services won't start

- Run full reset: `make re`
- Check Docker daemon is running: `docker info`
