#!/bin/bash

# FTP Server (vsftpd) startup script

# Read password from Docker Secrets
FTP_PASS=$(cat /run/secrets/ftp_password)

# www-data UID/GID (same as WordPress container)
WWW_DATA_UID=33
WWW_DATA_GID=33

# Create FTP user if not exists
if ! id "${FTP_USER}" &>/dev/null; then
    echo "Creating FTP user: ${FTP_USER}..."
    
    # Create user with same UID as www-data (allows read/write to WordPress files)
    # -o allows non-unique UID (sharing UID 33 with www-data)
    useradd -o -u ${WWW_DATA_UID} -g ${WWW_DATA_GID} -d /var/www/html -s /bin/bash "${FTP_USER}"
    
    # Set password
    echo "${FTP_USER}:${FTP_PASS}" | chpasswd
    
    echo "FTP user created with UID=${WWW_DATA_UID} (same as www-data)."
else
    echo "FTP user ${FTP_USER} already exists."
fi

echo "Starting vsftpd..."

# exec to let vsftpd take PID 1
exec vsftpd /etc/vsftpd.conf
