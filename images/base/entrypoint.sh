#!/bin/bash
# Entrypoint comú: ruta per defecte pel router, DNS, init específic del servei, SSH i servei principal.
set -u

# Totes les màquines surten pel router de la pràctica, no pel gateway de Docker.
if [ -n "${GATEWAY:-}" ]; then
  ip route replace default via "$GATEWAY" || echo "[entrypoint] no s'ha pogut canviar el gateway"
fi

if [ -n "${DNS_SERVER:-}" ]; then
  printf 'nameserver %s\nsearch asix.local\n' "$DNS_SERVER" > /etc/resolv.conf
fi

if [ -f /opt/init.sh ]; then
  bash /opt/init.sh || { echo "[entrypoint] init.sh ha fallat"; exit 1; }
fi

[ "${SSHD_FG:-0}" = "1" ] || /usr/sbin/sshd

exec "$@"
