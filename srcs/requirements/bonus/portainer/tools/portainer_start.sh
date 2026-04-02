#!/bin/bash

# Script de inicio para Portainer
# Portainer necesita acceso al socket de Docker para gestionar contenedores

echo "Iniciando Portainer..."

# exec para que Portainer tome el PID 1
# --bind: Puerto HTTP interno (NGINX hace el proxy con HTTPS)
# --data: Directorio para almacenar configuración de Portainer
exec /opt/portainer/portainer \
    --bind=:9000 \
    --data=/data
