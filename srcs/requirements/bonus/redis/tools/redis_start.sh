#!/bin/bash

# Script de inicio para Redis
# El exec es VITAL para que redis-server asuma el PID 1

echo "Iniciando Redis server..."
exec redis-server /etc/redis/redis.conf
