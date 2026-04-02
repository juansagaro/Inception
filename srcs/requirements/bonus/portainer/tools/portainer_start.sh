#!/bin/bash

# Portainer startup script
# Portainer needs access to the Docker socket to manage containers

echo "Starting Portainer..."

# exec to let Portainer take PID 1
# --bind: Internal HTTP port (NGINX proxies with HTTPS)
# --data: Directory to store Portainer configuration
exec /opt/portainer/portainer \
    --bind=:9000 \
    --data=/data
