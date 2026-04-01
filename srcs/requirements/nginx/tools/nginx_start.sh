#!/bin/bash

# Crear el certificado auto-firmado
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=42/OU=jsagaro-/CN=jsagaro-.42.fr"

# Ejecutar NGINX en primer plano
nginx -g "daemon off;"