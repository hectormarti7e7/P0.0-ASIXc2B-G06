#!/bin/bash
# Connecta els clients (màquines virtuals d'Isard a la xarxa itb 6) amb la intranet.
# S'executa a l'equip dels serveis, després de `docker compose up -d`:
#     sudo ./scripts/xarxa-clients.sh
#
# Els clients tenen una adreça d'itb 6 (192.168.50.0/24) i una ruta cap a la intranet
# (10.213.2.0/24) per aquest equip. Aquest equip reenvia el trànsit entre la targeta
# d'itb 6 i el pont de la intranet (br-intranet). Les respostes tornen pel router, que
# té una ruta cap a 192.168.50.0/24 (services/router/init.sh).
#
# És idempotent: es pot executar les vegades que calgui. Les regles no sobreviuen a un
# reinici de l'equip ni a una recreació de la xarxa: cal tornar-lo a executar.
set -euo pipefail

IF_ITB="${ITB_IF:-enp3s0}"            # targeta d'aquest equip connectada a itb 6
BR="br-intranet"                      # pont de la intranet (nom fix al docker-compose.yml)
ITB_NET="192.168.50.0/24"
INTRANET_NET="10.213.2.0/24"

[ "$EUID" -eq 0 ] || exec sudo -E "$0" "$@"

ip link show "$IF_ITB" >/dev/null 2>&1 \
  || { echo "ERROR: no existeix la targeta $IF_ITB (indica-la amb ITB_IF=...)"; exit 1; }
ip link show "$BR" >/dev/null 2>&1 \
  || { echo "ERROR: no existeix el pont $BR. Aixeca la infraestructura: docker compose up -d"; exit 1; }
iptables -S DOCKER-USER >/dev/null 2>&1 \
  || { echo "ERROR: no existeix la cadena DOCKER-USER. Docker està en marxa?"; exit 1; }

# Reenviament d'IPv4 (Docker ja el sol activar)
sysctl -qw net.ipv4.ip_forward=1

# Regles a DOCKER-USER, que Docker consulta abans de les seves pròpies
add_rule() {
  iptables -C DOCKER-USER "$@" 2>/dev/null || iptables -I DOCKER-USER "$@"
}
add_rule -i "$IF_ITB" -o "$BR" -s "$ITB_NET" -d "$INTRANET_NET" -j ACCEPT
add_rule -i "$BR" -o "$IF_ITB" -s "$INTRANET_NET" -d "$ITB_NET" -j ACCEPT

echo "[xarxa-clients] $IF_ITB ($ITB_NET) <-> $BR ($INTRANET_NET) reenviat"
iptables -S DOCKER-USER | grep -E "$IF_ITB|$BR" || true
