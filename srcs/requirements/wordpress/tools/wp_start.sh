#!/bin/bash

# 1. Read passwords from Docker Secrets
DB_PASS=$(cat /run/secrets/db_password)
WP_ADMIN_PASS=$(cat /run/secrets/wp_admin_password)
WP_USER_PASS=$(cat /run/secrets/wp_user_password)

# First-time setup if wp-config.php doesn't exist
if [ ! -f wp-config.php ]; then
    echo "Configurando WordPress por primera vez..."

    # Download WordPress core
    wp core download --locale=es_ES --allow-root

    # Create wp-config.php
    wp config create \
        --dbname=${SQL_DATABASE} \
        --dbuser=${SQL_USER} \
        --dbpass=${DB_PASS} \
        --dbhost=mariadb:3306 \
        --allow-root

    # Add Redis config BEFORE install
    wp config set WP_REDIS_HOST "${WP_REDIS_HOST}" --allow-root
    wp config set WP_REDIS_PORT "${WP_REDIS_PORT}" --allow-root
    wp config set WP_CACHE true --raw --allow-root

    # Install WordPress (creates tables + admin user)
    wp core install \
        --url=https://${DOMAIN_NAME} \
        --title="Inception 42" \
        --admin_user=${WP_ADMIN_USER} \
        --admin_password=${WP_ADMIN_PASS} \
        --admin_email=${WP_ADMIN_EMAIL} \
        --allow-root

    # Create additional user (required by subject)
    wp user create \
        ${WP_USER} \
        ${WP_USER_EMAIL} \
        --role=author \
        --user_pass=${WP_USER_PASS} \
        --allow-root

    # Setup Redis Object Cache plugin
    wp plugin install redis-cache --activate --allow-root
    wp redis enable --allow-root

    echo "Redis Object Cache configurado correctamente."
else
    echo "WordPress ya está configurado. Saltando instalación."
fi

# Fix permissions for NGINX/PHP-FPM
chown -R www-data:www-data /var/www/html

# Start PHP-FPM in foreground (PID 1)
exec php-fpm8.2 -F
