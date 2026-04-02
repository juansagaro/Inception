#!/bin/bash

# Adminer startup script
# Uses PHP built-in server (perfect for Adminer)

echo "Iniciando Adminer en puerto 8080..."

# exec so PHP takes PID 1 and receives Docker signals
exec php -S 0.0.0.0:8080 -t /var/www/adminer
