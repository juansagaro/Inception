#!/bin/bash

# 1. Leer las contraseñas de los archivos seguros de Docker Secrets
# (Asegúrate de que los nombres coinciden con los que pusiste en el docker-compose.yml)
DB_PASS=$(cat /run/secrets/db_password)
DB_ROOT_PASS=$(cat /run/secrets/db_root_password)

# 2. Crear un archivo temporal con las instrucciones SQL
# Usamos las variables del .env para los nombres, y los secretos para las claves
cat << EOF > /tmp/init.sql
CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;
CREATE USER IF NOT EXISTS \`${SQL_USER}\`@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO \`${SQL_USER}\`@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
FLUSH PRIVILEGES;
EOF

# 3. Arrancar MariaDB pasándole el archivo de instrucciones
# Esto lo hace todo en un solo paso, sin fallos de socket, y anclado al PID 1
exec mysqld_safe --init-file=/tmp/init.sql
