FROM debian:bookworm

# Install Redis
RUN apt-get update && apt-get install -y \
    redis-server \
    && rm -rf /var/lib/apt/lists/*

# Copy config and entrypoint
COPY conf/redis.conf /etc/redis/redis.conf
COPY tools/redis_start.sh /usr/local/bin/redis_start.sh

# Make executable
RUN chmod +x /usr/local/bin/redis_start.sh

# Redis port
EXPOSE 6379

# Run entrypoint
ENTRYPOINT ["/usr/local/bin/redis_start.sh"]
