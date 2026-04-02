#!/bin/bash

# Script de inicio para FTP Server (vsftpd)

# Leer contraseña desde Docker Secrets
FTP_PASS=$(cat /run/secrets/ftp_password)

# Crear usuario FTP si no existe
if ! id "${FTP_USER}" &>/dev/null; then
    echo "Creando usuario FTP: ${FTP_USER}..."
    
    # Crear usuario con home en /var/www/html (volumen de WordPress)
    useradd -m -d /var/www/html -s /bin/bash "${FTP_USER}"
    
    # Establecer contraseña
    echo "${FTP_USER}:${FTP_PASS}" | chpasswd
    
    # Asegurar permisos correctos
    chown -R "${FTP_USER}:${FTP_USER}" /var/www/html
    
    echo "Usuario FTP creado correctamente."
else
    echo "Usuario FTP ${FTP_USER} ya existe."
fi

echo "Iniciando vsftpd..."

# exec para que vsftpd tome el PID 1
exec vsftpd /etc/vsftpd.conf
