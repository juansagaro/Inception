FROM debian:bookworm

# Install NGINX (lightweight server for static files)
RUN apt-get update && apt-get install -y \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Copy config and site files
COPY conf/nginx.conf /etc/nginx/sites-available/default
COPY html/ /var/www/html/
COPY tools/static_start.sh /usr/local/bin/static_start.sh

# Make executable
RUN chmod +x /usr/local/bin/static_start.sh

# Internal port (not exposed externally, Docker network only)
EXPOSE 80

# Run NGINX
ENTRYPOINT ["/usr/local/bin/static_start.sh"]
