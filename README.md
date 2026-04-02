<h1 align="center">Inception</h1>

<p align="center">
  <strong>A containerized web infrastructure built from scratch</strong><br>
  System administration project for 42 School
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Score-125%2F100-success?style=flat-square" alt="Score"/>
  <img src="https://img.shields.io/badge/Bonus-5%2F5-blue?style=flat-square" alt="Bonus"/>
  <img src="https://img.shields.io/badge/42-Madrid-black?style=flat-square" alt="42 Madrid"/>
</p>

---

## 📋 Overview

Inception demonstrates infrastructure-as-code principles by building a complete web hosting stack using **custom Docker images** - no pre-built images from DockerHub. Each service runs in its own container, orchestrated with Docker Compose.

### Key Achievements

- 8 custom Dockerfiles built from `debian:bookworm`
- TLS-only access via NGINX reverse proxy (TLSv1.2/1.3)
- Docker Secrets for credential management
- Persistent volumes with host-mounted storage
- Complete bonus: Redis, Adminer, FTP, Portainer, Static Site

---

## 🏗️ Architecture

```mermaid
graph TB
    subgraph External
        Client([Client])
    end
    
    subgraph Docker Network
        Client -->|:443 HTTPS| NGINX
        
        subgraph Containers
            NGINX[NGINX<br/>TLS Termination]
            WP[WordPress<br/>PHP-FPM]
            DB[(MariaDB)]
            REDIS[(Redis)]
            ADM[Adminer]
            FTP[FTP Server]
            PORT[Portainer]
            STATIC[Static Site]
        end
        
        NGINX --> WP
        NGINX --> ADM
        NGINX --> PORT
        NGINX --> STATIC
        
        WP --> DB
        WP --> REDIS
        ADM --> DB
        FTP --> WP
    end
    
    subgraph Host Storage
        VOL_WP[("/home/login/data/wordpress")]
        VOL_DB[("/home/login/data/mariadb")]
        VOL_PORT[("/home/login/data/portainer")]
    end
    
    WP -.-> VOL_WP
    DB -.-> VOL_DB
    PORT -.-> VOL_PORT
    FTP -.-> VOL_WP

    style NGINX fill:#009639,color:#fff
    style WP fill:#21759B,color:#fff
    style DB fill:#003545,color:#fff
    style REDIS fill:#DC382D,color:#fff
```

---

## 📦 Services

<table>
<tr>
<td width="50%">

### NGINX
![NGINX](https://img.shields.io/badge/NGINX-009639?style=flat-square&logo=nginx&logoColor=white)

Reverse proxy with TLS termination. Single entry point for all HTTPS traffic. Routes requests to appropriate backend services.

**Port:** 443

</td>
<td width="50%">

### WordPress
![WordPress](https://img.shields.io/badge/WordPress-21759B?style=flat-square&logo=wordpress&logoColor=white)

Content management system running with PHP-FPM. Connected to MariaDB for data persistence and Redis for object caching.

**URL:** `https://jsagaro-.42.fr`

</td>
</tr>
<tr>
<td width="50%">

### MariaDB
![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=flat-square&logo=mariadb&logoColor=white)

Relational database storing WordPress content. Configured with InnoDB engine for transactional support.

**Access:** Internal only

</td>
<td width="50%">

### Redis
![Redis](https://img.shields.io/badge/Redis-DC382D?style=flat-square&logo=redis&logoColor=white)

In-memory cache for WordPress object caching. Improves page load performance by reducing database queries.

**Access:** Internal only

</td>
</tr>
<tr>
<td width="50%">

### Adminer
![Adminer](https://img.shields.io/badge/Adminer-4479A1?style=flat-square&logo=adminer&logoColor=white)

Lightweight database administration tool. Web interface for managing MariaDB tables, queries, and backups.

**URL:** `https://adminer.jsagaro-.42.fr`

</td>
<td width="50%">

### Portainer
![Portainer](https://img.shields.io/badge/Portainer-13BEF9?style=flat-square&logo=portainer&logoColor=white)

Docker container management GUI. Monitor, start, stop, and inspect containers through web interface.

**URL:** `https://portainer.jsagaro-.42.fr`

</td>
</tr>
<tr>
<td width="50%">

### FTP Server
![FTP](https://img.shields.io/badge/vsftpd-333333?style=flat-square&logo=files&logoColor=white)

Secure file transfer access to WordPress files. Allows direct upload/download of themes, plugins, and media.

**Port:** 21

</td>
<td width="50%">

### Static Site
![Static](https://img.shields.io/badge/Portfolio-000000?style=flat-square&logo=html5&logoColor=white)

Personal portfolio website. Pure HTML/CSS/JS served directly by NGINX without backend processing.

**URL:** `https://static.jsagaro-.42.fr`

</td>
</tr>
</table>

---

## 🚀 Quick Start

```bash
# Clone and enter directory
git clone https://github.com/jsagaro-/inception.git
cd inception

# Setup secrets (create password files)
mkdir -p secrets
echo "secure_db_pass" > secrets/db_password.txt
echo "secure_root_pass" > secrets/db_root_password.txt
echo "secure_wp_admin" > secrets/wp_admin_password.txt
echo "secure_wp_user" > secrets/wp_user_password.txt
echo "secure_ftp_pass" > secrets/ftp_password.txt

# Add domains to hosts file
sudo tee -a /etc/hosts << EOF
127.0.0.1 jsagaro-.42.fr
127.0.0.1 adminer.jsagaro-.42.fr
127.0.0.1 static.jsagaro-.42.fr
127.0.0.1 portainer.jsagaro-.42.fr
EOF

# Build and launch
make all

# Access the site
open https://jsagaro-.42.fr
```

---

## 🛠️ Makefile Commands

| Command | Description |
|---------|-------------|
| `make all` | Build images and start containers |
| `make stop` | Pause containers (keep state) |
| `make start` | Resume paused containers |
| `make status` | Show container status |
| `make logs` | Stream real-time logs |
| `make clean` | Stop and remove containers |
| `make fclean` | Full cleanup (images, volumes, data) |
| `make re` | Rebuild from scratch |

---

## 📁 Project Structure

```
inception/
├── Makefile                    # Build orchestration
├── secrets/                    # Docker secrets (gitignored)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   ├── wp_user_password.txt
│   └── ftp_password.txt
├── srcs/
│   ├── .env                    # Environment config
│   ├── docker-compose.yml      # Service definitions
│   └── requirements/
│       ├── nginx/              # Reverse proxy
│       ├── mariadb/            # Database
│       ├── wordpress/          # CMS + PHP-FPM
│       └── bonus/
│           ├── redis/          # Cache
│           ├── adminer/        # DB admin
│           ├── static/         # Portfolio
│           ├── ftp/            # File transfer
│           └── portainer/      # Container management
└── docs/                       # Documentation
    ├── README.md               # 42 evaluation version
    ├── USER_DOC.md             # User guide
    └── DEV_DOC.md              # Developer guide
```

---

## 🔒 Security

- **TLS 1.2/1.3 only** - No legacy SSL protocols
- **Docker Secrets** - Passwords never in environment variables
- **Single entry point** - Only NGINX exposed externally
- **Isolated network** - Bridge network with container DNS
- **No root passwords in images** - Secrets mounted at runtime

---

## 📚 Documentation

- [docs/README.md](docs/README.md) - Technical choices and 42 evaluation notes
- [docs/USER_DOC.md](docs/USER_DOC.md) - End-user operation guide
- [docs/DEV_DOC.md](docs/DEV_DOC.md) - Developer setup and maintenance

---

## 👤 Author

**jsagaro-** - 42 Madrid
