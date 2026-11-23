#!/bin/bash
# Máquina de datos: Redis escuchando en su IP interna, puerto 6379.
# apt solo funciona si el NAT ya existe, porque esta máquina no tiene IP pública.
apt-get update -y
apt-get install -y redis-server
INTERNA=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
# Por defecto Redis solo escucha en 127.0.0.1. Se abre también la IP interna;
# quién puede llegar a ella lo decide la regla de cortafuegos por etiqueta.
sed -i "s/^bind .*/bind 127.0.0.1 $INTERNA/" /etc/redis/redis.conf
sed -i "s/^protected-mode yes/protected-mode no/" /etc/redis/redis.conf
systemctl restart redis-server
