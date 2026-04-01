#!/bin/bash

# 1. Leer las contraseñas desde los Docker Secrets
DB_PASS=$(cat /run/secrets/db_password)
WP_ADMIN_PASS=$(cat /run/secrets/wp_admin_password)
WP_USER_PASS=$(cat /run/secrets/wp_user_password)

# Si wp-config.php no existe, significa que es la primera vez que se lanza
if [ ! -f wp-config.php ]; then
    echo "Configurando WordPress por primera vez..."

    # Descargar WordPress
    wp core download --locale=es_ES --allow-root

    # Crear el archivo wp-config.php usando las variables de entorno y el secreto de la BD
    wp config create \
        --dbname=${SQL_DATABASE} \
        --dbuser=${SQL_USER} \
        --dbpass=${DB_PASS} \
        --dbhost=mariadb:3306 \
        --allow-root

    # Instalar WordPress (crea las tablas y el usuario Admin)
    wp core install \
        --url=https://${DOMAIN_NAME} \
        --title="Inception 42" \
        --admin_user=${WP_ADMIN_USER} \
        --admin_password=${WP_ADMIN_PASS} \
        --admin_email=${WP_ADMIN_EMAIL} \
        --allow-root

    # Crear usuario adicional exigido por el subject
    wp user create \
        ${WP_USER} \
        ${WP_USER_EMAIL} \
        --role=author \
        --user_pass=${WP_USER_PASSWORD} \
        --allow-root
else
    echo "WordPress ya está configurado. Saltando instalación."
fi

# Ajustar permisos para que NGINX y PHP-FPM puedan leer y escribir
chown -R www-data:www-data /var/www/html

# Arrancar PHP-FPM en primer plano (PID 1)
exec php-fpm8.2 -F
