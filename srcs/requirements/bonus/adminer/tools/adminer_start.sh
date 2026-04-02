#!/bin/bash

# Script de inicio para Adminer
# Usa el servidor web integrado de PHP (perfecto para Adminer)

echo "Iniciando Adminer en puerto 8080..."

# exec para que PHP tome el PID 1 y reciba las señales de Docker
exec php -S 0.0.0.0:8080 -t /var/www/adminer
