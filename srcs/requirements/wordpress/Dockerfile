FROM debian:bookworm

# Install PHP, extensions, and wget for wp-cli
RUN apt-get update && apt-get install -y \
    php8.2-fpm \
    php8.2-mysql \
    wget \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Download and install WP-CLI
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Create PHP-FPM runtime dir
RUN mkdir -p /run/php

# Copy config and entrypoint
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/wp_start.sh /usr/local/bin/wp_start.sh
RUN chmod +x /usr/local/bin/wp_start.sh

# Expose FastCGI port for NGINX
EXPOSE 9000

# Set working dir to shared volume
WORKDIR /var/www/html

# Run entrypoint
ENTRYPOINT ["/usr/local/bin/wp_start.sh"]
