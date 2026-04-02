#!/bin/bash

echo "Iniciando servidor de sitio estático..."

# exec para que NGINX tome el PID 1
exec nginx -g "daemon off;"
