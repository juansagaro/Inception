FROM debian:bookworm

# Instalar vsftpd (Very Secure FTP Daemon)
RUN apt-get update && apt-get install -y \
    vsftpd \
    && rm -rf /var/lib/apt/lists/*

# Copiar configuración y script
COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/ftp_start.sh /usr/local/bin/ftp_start.sh

# Dar permisos de ejecución
RUN chmod +x /usr/local/bin/ftp_start.sh

# Crear directorio para el modo pasivo
RUN mkdir -p /var/run/vsftpd/empty

# Puerto de control FTP + rango de puertos pasivos
EXPOSE 21 21100-21110

# Arrancar vsftpd
ENTRYPOINT ["/usr/local/bin/ftp_start.sh"]
