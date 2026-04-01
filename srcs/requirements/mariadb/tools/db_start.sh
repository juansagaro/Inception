#!/bin/bash

# 1. Crear un archivo temporal con las instrucciones SQL
cat << EOF > /tmp/init.sql
CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;
CREATE USER IF NOT EXISTS \`${SQL_USER}\`@'%' IDENTIFIED BY '${SQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO \`${SQL_USER}\`@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

# 2. Arrancar MariaDB pasándole el archivo de instrucciones
# Esto lo hace todo en un solo paso, sin fallos de socket, y anclado al PID 1
exec mysqld_safe --init-file=/tmp/init.sql