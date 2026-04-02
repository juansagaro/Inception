FROM debian:bookworm

# Install PHP and wget to download Adminer
RUN apt-get update && apt-get install -y \
    php8.2 \
    php8.2-mysql \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Create Adminer directory
RUN mkdir -p /var/www/adminer

# Download Adminer (v5.4.2 - PHP 8.2 compatible)
RUN wget -O /var/www/adminer/index.php \
    https://github.com/vrana/adminer/releases/download/v5.4.2/adminer-5.4.2.php

# Copy entrypoint
COPY tools/adminer_start.sh /usr/local/bin/adminer_start.sh
RUN chmod +x /usr/local/bin/adminer_start.sh

# Working directory
WORKDIR /var/www/adminer

# Internal Adminer port
EXPOSE 8080

# Run entrypoint
ENTRYPOINT ["/usr/local/bin/adminer_start.sh"]
