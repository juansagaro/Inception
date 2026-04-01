FROM debian:bookworm

# Instalar PHP y extensiones necesarias, más wget para descargar wp-cli
RUN apt-get update && apt-get install -y \
    php8.2-fpm \
    php8.2-mysql \
    wget \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Descargar e instalar WP-CLI (la línea de comandos de WordPress)
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Preparar la carpeta de PHP-FPM para evitar errores al arrancar
RUN mkdir -p /run/php

# Copiar la configuración y el script
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/wp_start.sh /usr/local/bin/wp_start.sh
RUN chmod +x /usr/local/bin/wp_start.sh

# Exponer el puerto para NGINX
EXPOSE 9000

# Arrancar
ENTRYPOINT ["/usr/local/bin/wp_start.sh"]