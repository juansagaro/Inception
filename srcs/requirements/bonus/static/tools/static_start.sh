#!/bin/bash

echo "Iniciando servidor de sitio estático..."

# exec so NGINX takes PID 1
exec nginx -g "daemon off;"
