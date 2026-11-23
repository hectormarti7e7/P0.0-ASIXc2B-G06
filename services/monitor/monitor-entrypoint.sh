#!/bin/bash
# Entrypoint de MON-NCC: gateway pel router, DNS de la pràctica, SSH i Uptime Kuma.
set -u

# Tot el trànsit surt pel router de la pràctica, no pel gateway de Docker
if [ -n "${GATEWAY:-}" ]; then
  ip route replace default via "$GATEWAY" || echo "[monitor] no s'ha pogut canviar el gateway"
fi

if [ -n "${DNS_SERVER:-}" ]; then
  printf 'nameserver %s\nsearch asix.local\n' "$DNS_SERVER" > /etc/resolv.conf
fi

/usr/sbin/sshd

exec "$@"
