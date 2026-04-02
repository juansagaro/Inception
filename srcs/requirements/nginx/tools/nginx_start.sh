#!/bin/bash

# Comprobamos si el certificado ya existe para no pisarlo
if [ ! -f /etc/ssl/certs/nginx-selfsigned.crt ]; then
    echo "Generando certificado SSL con SAN para ${DOMAIN_NAME} y subdominios..."
    
    # Crear certificado con Subject Alternative Names (SAN)
    # Esto permite que un solo certificado cubra múltiples subdominios
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/nginx-selfsigned.key \
        -out /etc/ssl/certs/nginx-selfsigned.crt \
        -subj "/C=ES/ST=Madrid/L=Madrid/O=42/OU=jsagaro-/CN=${DOMAIN_NAME}" \
        -addext "subjectAltName=DNS:${DOMAIN_NAME},DNS:adminer.${DOMAIN_NAME},DNS:static.${DOMAIN_NAME},DNS:portainer.${DOMAIN_NAME}"
    
    echo "Certificado generado para: ${DOMAIN_NAME}, adminer.${DOMAIN_NAME}, static.${DOMAIN_NAME}, portainer.${DOMAIN_NAME}"
fi

# El exec es VITAL para que NGINX asuma el PID 1
exec nginx -g "daemon off;"
