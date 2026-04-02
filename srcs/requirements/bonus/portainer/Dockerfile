FROM debian:bookworm

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Download Portainer CE (Community Edition)
RUN wget -O /tmp/portainer.tar.gz \
    https://github.com/portainer/portainer/releases/download/2.19.4/portainer-2.19.4-linux-amd64.tar.gz \
    && tar -xzf /tmp/portainer.tar.gz -C /opt \
    && rm /tmp/portainer.tar.gz

# Create data directory for Portainer
RUN mkdir -p /data

# Copy startup script
COPY tools/portainer_start.sh /usr/local/bin/portainer_start.sh
RUN chmod +x /usr/local/bin/portainer_start.sh

# Portainer HTTP port (HTTPS handled by NGINX)
EXPOSE 9000

# Start Portainer
ENTRYPOINT ["/usr/local/bin/portainer_start.sh"]
