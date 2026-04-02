*This project has been created as part of the 42 curriculum by jsagaro-.*

# Inception

## Description

Inception is a system administration project that demonstrates infrastructure virtualization using Docker. The objective is to build a complete web hosting environment from scratch, without relying on pre-built Docker images from DockerHub.

The infrastructure consists of:
- **NGINX** - Reverse proxy with TLS termination (TLSv1.2/TLSv1.3 only)
- **WordPress** - Content management system with PHP-FPM
- **MariaDB** - Relational database for WordPress
- **Redis** - Object cache for WordPress performance (bonus)
- **Adminer** - Web-based database administration (bonus)
- **FTP Server** - File transfer access to WordPress files (bonus)
- **Portainer** - Docker container management GUI (bonus)
- **Static Website** - Personal portfolio site (bonus)

All services run in isolated containers connected via a Docker bridge network, with NGINX as the single entry point on port 443.

---

## Instructions

### Prerequisites

- Linux virtual machine (Debian/Ubuntu recommended)
- Docker 20.10+ with Docker Compose V2
- Domain entries in `/etc/hosts`:
  ```
  127.0.0.1 jsagaro-.42.fr
  127.0.0.1 adminer.jsagaro-.42.fr
  127.0.0.1 static.jsagaro-.42.fr
  127.0.0.1 portainer.jsagaro-.42.fr
  ```

### Setup

1. Clone the repository
2. Create secrets files in `secrets/` directory:
   - `db_password.txt`
   - `db_root_password.txt`
   - `wp_admin_password.txt`
   - `wp_user_password.txt`
   - `ftp_password.txt`

### Build and Run

```bash
make all      # Build and start infrastructure
make stop     # Pause containers (keep state)
make start    # Resume paused containers
make status   # Check container status
make logs     # View real-time logs
make clean    # Stop and remove containers
make fclean   # Full cleanup (removes all data)
make re       # Rebuild from scratch
```

### Access

- WordPress: `https://jsagaro-.42.fr`
- Admin Panel: `https://jsagaro-.42.fr/wp-admin`
- Adminer: `https://adminer.jsagaro-.42.fr`
- Portainer: `https://portainer.jsagaro-.42.fr`
- Portfolio: `https://static.jsagaro-.42.fr`

---

## Resources

### Documentation References

- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Specification](https://docs.docker.com/compose/compose-file/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress Developer Resources](https://developer.wordpress.org/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/)
- [Debian Wiki](https://wiki.debian.org/)

### AI Usage Disclosure

AI tools (Claude) were used during this project for:
- **Code review:** Validating Dockerfile best practices and identifying potential issues
- **Comment translation:** Converting Spanish comments to English
- **Documentation drafting:** Structuring and formatting markdown documentation
- **Debugging assistance:** Troubleshooting container networking and configuration issues

All AI-generated content was reviewed, tested, and validated by the author. The core infrastructure design, implementation decisions, and problem-solving were performed independently.

---

## Technical Choices & Comparisons

### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker Containers |
|--------|------------------|-------------------|
| **Isolation** | Full OS isolation with hypervisor | Process-level isolation sharing host kernel |
| **Resource Usage** | Heavy - each VM runs complete OS | Lightweight - shares host kernel |
| **Startup Time** | Minutes | Seconds |
| **Portability** | Limited by hypervisor compatibility | Highly portable via images |
| **Use Case** | Running different OS, full isolation | Microservices, consistent environments |

**Project Choice:** Docker containers were mandated by the subject. They provide sufficient isolation for web services while being resource-efficient and fast to deploy. The infrastructure runs inside a VM as required, combining VM-level isolation with container efficiency.

### Secrets vs Environment Variables

| Aspect | Environment Variables | Docker Secrets |
|--------|----------------------|----------------|
| **Storage** | Plain text in `.env` file | Encrypted, mounted as files in `/run/secrets/` |
| **Visibility** | Visible via `docker inspect` | Not exposed in container metadata |
| **Access** | Available to all processes | Mounted read-only in container filesystem |
| **Git Safety** | Risk of accidental commit | Separate directory, easily gitignored |

**Project Choice:** Sensitive credentials (passwords) are stored as Docker Secrets, while non-sensitive configuration (usernames, domain, ports) uses environment variables. This follows security best practices and 42 subject requirements.

### Docker Network vs Host Network

| Aspect | Docker Bridge Network | Host Network |
|--------|----------------------|--------------|
| **Isolation** | Containers isolated from host | No network isolation |
| **Port Mapping** | Explicit port exposure required | Container uses host ports directly |
| **Container Communication** | Via service names (DNS) | Via localhost |
| **Security** | Better - limited attack surface | Worse - all ports exposed |

**Project Choice:** Bridge network (`jsagaro-net`) isolates containers and allows service discovery via DNS names. Only NGINX exposes port 443 externally, enforcing the subject requirement that NGINX is the single entry point.

### Docker Volumes vs Bind Mounts

| Aspect | Named Volumes | Bind Mounts |
|--------|---------------|-------------|
| **Management** | Docker manages location | User specifies exact path |
| **Portability** | Volume name abstraction | Path must exist on host |
| **Backup** | Via Docker commands | Direct filesystem access |
| **Performance** | Optimized by Docker | Native filesystem performance |

**Project Choice:** Named volumes with `local` driver and `bind` option are used. This satisfies the subject requirement for named volumes while storing data at the specified host path (`/home/login/data/`). This hybrid approach provides Docker volume management with predictable host storage locations.

---

## Additional Documentation

- [USER_DOC.md](./USER_DOC.md) - End-user guide for operating the infrastructure
- [DEV_DOC.md](./DEV_DOC.md) - Developer guide for maintenance and extension
