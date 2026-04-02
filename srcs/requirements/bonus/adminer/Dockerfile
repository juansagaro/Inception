FROM debian:bookworm

# Instalar PHP y wget para descargar Adminer
RUN apt-get update && apt-get install -y \
    php8.2 \
    php8.2-mysql \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Crear directorio para Adminer
RUN mkdir -p /var/www/adminer

# Descargar Adminer (un solo archivo PHP)
RUN wget -O /var/www/adminer/index.php \
    https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php

# Copiar script de inicio
COPY tools/adminer_start.sh /usr/local/bin/adminer_start.sh
RUN chmod +x /usr/local/bin/adminer_start.sh

# Directorio de trabajo
WORKDIR /var/www/adminer

# Puerto interno de Adminer
EXPOSE 8080

# Arrancar con el script
ENTRYPOINT ["/usr/local/bin/adminer_start.sh"]
