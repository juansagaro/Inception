#!/bin/bash

# 1. Read passwords from Docker Secrets
DB_PASS=$(cat /run/secrets/db_password)
DB_ROOT_PASS=$(cat /run/secrets/db_root_password)

# 2. Create temp SQL init file
cat << EOF > /tmp/init.sql
CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;
CREATE USER IF NOT EXISTS \`${SQL_USER}\`@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO \`${SQL_USER}\`@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
FLUSH PRIVILEGES;
EOF

# 3. Start MariaDB with init file (keeps PID 1)
exec mysqld_safe --init-file=/tmp/init.sql
