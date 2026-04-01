#!/bin/bash

# Comprobamos si el certificado ya existe para no pisarlo
if [ ! -f /etc/ssl/certs/nginx-selfsigned.crt ]; then
    echo "Generando certificado SSL para $DOMAIN_NAME..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/nginx-selfsigned.key \
        -out /etc/ssl/certs/nginx-selfsigned.crt \
        -subj "/C=ES/ST=Madrid/L=Madrid/O=42/OU=jsagaro-/CN=${DOMAIN_NAME}"
fi

# El exec es VITAL para que NGINX asuma el PID 1
exec nginx -g "daemon off;"
