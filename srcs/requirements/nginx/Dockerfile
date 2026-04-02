FROM debian:bookworm

# Install NGINX and OpenSSL
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Copy config files
COPY ./conf/nginx.conf /etc/nginx/sites-available/default
COPY ./tools/nginx_start.sh /var/www/nginx_start.sh

# Make script executable
RUN chmod +x /var/www/nginx_start.sh

# Only expose 443 (TLS)
EXPOSE 443

# Run entrypoint
ENTRYPOINT ["/var/www/nginx_start.sh"]
