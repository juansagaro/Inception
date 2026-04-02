FROM debian:bookworm

# Instalar dependencias necesarias
RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Descargar Portainer CE (Community Edition)
RUN wget -O /tmp/portainer.tar.gz \
    https://github.com/portainer/portainer/releases/download/2.19.4/portainer-2.19.4-linux-amd64.tar.gz \
    && tar -xzf /tmp/portainer.tar.gz -C /opt \
    && rm /tmp/portainer.tar.gz

# Crear directorio para datos de Portainer
RUN mkdir -p /data

# Copiar script de inicio
COPY tools/portainer_start.sh /usr/local/bin/portainer_start.sh
RUN chmod +x /usr/local/bin/portainer_start.sh

# Puerto HTTP de Portainer (el HTTPS lo maneja NGINX)
EXPOSE 9000

# Arrancar Portainer
ENTRYPOINT ["/usr/local/bin/portainer_start.sh"]
