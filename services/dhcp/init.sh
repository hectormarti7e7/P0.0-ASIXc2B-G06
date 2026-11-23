#!/bin/bash
# DHCP-NCC: servidor DHCP (dnsmasq) de la intranet. Reparteix 10.213.2.100-200 amb el router
# i el DNS de la pràctica. L'executa l'entrypoint abans d'arrencar dnsmasq.
set -e

mkdir -p /var/lib/misc

cat > /etc/dnsmasq.d/p00-dhcp.conf <<'EOF'
# Només fa de DHCP: el DNS és un altre contenidor (DNS-N06)
port=0

# Només escolta a la seva adreça de la intranet
listen-address=10.213.2.67
bind-interfaces

# Rang repartit, màscara i temps de cessió
dhcp-range=10.213.2.100,10.213.2.200,255.255.255.0,12h
dhcp-authoritative
dhcp-leasefile=/var/lib/misc/dnsmasq.leases

# Opcions que reben els clients
dhcp-option=option:router,10.213.2.254
dhcp-option=option:dns-server,10.213.2.53
dhcp-option=option:domain-name,asix.local

# Registre de les peticions (surt per docker logs)
log-dhcp
EOF

# dnsmasq no llegeix /etc/dnsmasq.d si no l'arrenca el servei del sistema:
# el command del contenidor li passa el fitxer amb --conf-file
dnsmasq --test --conf-file=/etc/dnsmasq.d/p00-dhcp.conf
echo "[dhcp] configuració vàlida: rang 10.213.2.100-200"
