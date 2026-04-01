FROM debian:bookworm

# Instalar NGINX y OpenSSL
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Copiar la configuración
COPY ./conf/nginx.conf /etc/nginx/sites-available/default
COPY ./tools/nginx_start.sh /var/www/nginx_start.sh

# Dar permisos al script
RUN chmod +x /var/www/nginx_start.sh

# Exponer solo el puerto 443
EXPOSE 443

# Arrancar con el script
ENTRYPOINT ["/var/www/nginx_start.sh"]
