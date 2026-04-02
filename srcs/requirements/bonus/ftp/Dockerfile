FROM debian:bookworm

# Install vsftpd (Very Secure FTP Daemon)
RUN apt-get update && apt-get install -y \
    vsftpd \
    && rm -rf /var/lib/apt/lists/*

# Copy config and startup script
COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/ftp_start.sh /usr/local/bin/ftp_start.sh

# Make script executable
RUN chmod +x /usr/local/bin/ftp_start.sh

# Create directory for passive mode
RUN mkdir -p /var/run/vsftpd/empty

# FTP control port + passive port range
EXPOSE 21 21100-21110

# Start vsftpd
ENTRYPOINT ["/usr/local/bin/ftp_start.sh"]
