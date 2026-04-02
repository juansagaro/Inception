#!/bin/bash

# FTP Server (vsftpd) startup script

# Read password from Docker Secrets
FTP_PASS=$(cat /run/secrets/ftp_password)

# Create FTP user if not exists
if ! id "${FTP_USER}" &>/dev/null; then
    echo "Creating FTP user: ${FTP_USER}..."
    
    # Create user with home at /var/www/html (WordPress volume)
    useradd -m -d /var/www/html -s /bin/bash "${FTP_USER}"
    
    # Set password
    echo "${FTP_USER}:${FTP_PASS}" | chpasswd
    
    # Ensure correct permissions
    chown -R "${FTP_USER}:${FTP_USER}" /var/www/html
    
    echo "FTP user created successfully."
else
    echo "FTP user ${FTP_USER} already exists."
fi

echo "Starting vsftpd..."

# exec to let vsftpd take PID 1
exec vsftpd /etc/vsftpd.conf
