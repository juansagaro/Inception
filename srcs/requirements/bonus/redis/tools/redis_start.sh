#!/bin/bash

# Redis startup script
# exec is critical for PID 1

echo "Iniciando Redis server..."
exec redis-server /etc/redis/redis.conf
