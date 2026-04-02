FROM debian:bookworm

# Instalar NGINX (servidor ligero para archivos estáticos)
RUN apt-get update && apt-get install -y \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Copiar configuración y archivos del sitio
COPY conf/nginx.conf /etc/nginx/sites-available/default
COPY html/ /var/www/html/
COPY tools/static_start.sh /usr/local/bin/static_start.sh

# Dar permisos
RUN chmod +x /usr/local/bin/static_start.sh

# Puerto interno (NO expuesto al exterior, solo a la red Docker)
EXPOSE 80

# Arrancar NGINX
ENTRYPOINT ["/usr/local/bin/static_start.sh"]
