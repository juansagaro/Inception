FROM debian:bookworm

# Instalar Redis
RUN apt-get update && apt-get install -y \
    redis-server \
    && rm -rf /var/lib/apt/lists/*

# Copiar configuración y script
COPY conf/redis.conf /etc/redis/redis.conf
COPY tools/redis_start.sh /usr/local/bin/redis_start.sh

# Dar permisos de ejecución
RUN chmod +x /usr/local/bin/redis_start.sh

# Puerto de Redis
EXPOSE 6379

# Arrancar Redis
ENTRYPOINT ["/usr/local/bin/redis_start.sh"]
