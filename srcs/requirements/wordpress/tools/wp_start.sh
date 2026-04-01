#!/bin/bash

# Aseguramos que la carpeta existe y entramos en ella
mkdir -p /var/www/html
cd /var/www/html

# Si wp-config.php no existe, significa que es la primera vez que se lanza
if [ ! -f wp-config.php ]; then
    echo "Configurando WordPress por primera vez..."

    # Descargar WordPress en el idioma deseado
    wp core download --locale=es_ES --allow-root

    # Crear el archivo wp-config.php usando las variables de entorno
    wp config create \
        --dbname=${SQL_DATABASE} \
        --dbuser=${SQL_USER} \
        --dbpass=${SQL_PASSWORD} \
        --dbhost=mariadb:3306 \
        --allow-root

    # Instalar WordPress (crea las tablas en la base de datos y el usuario Admin)
    # Las variables WP_ADMIN_USER y WP_ADMIN_PASSWORD las añadiremos al .env ahora
    wp core install \
        --url=${DOMAIN_NAME} \
        --title="Inception 42" \
        --admin_user=${WP_ADMIN_USER} \
        --admin_password=${WP_ADMIN_PASSWORD} \
        --admin_email=${WP_ADMIN_EMAIL} \
        --allow-root

    # El subject suele pedir un usuario adicional (Autor/Editor)
    wp user create \
        ${WP_USER} \
        ${WP_USER_EMAIL} \
        --role=author \
        --user_pass=${WP_USER_PASSWORD} \
        --allow-root
else
    echo "WordPress ya está configurado. Saltando instalación."
fi

# Ajustar permisos para que NGINX pueda leer los archivos
chown -R www-data:www-data /var/www/html

# Arrancar PHP-FPM en primer plano (PID 1)
# En Debian Bookworm, la versión de PHP suele ser la 8.2
exec php-fpm8.2 -F