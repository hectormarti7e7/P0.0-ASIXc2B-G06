#!/bin/bash
# DNS-NCC: dnsmasq com a servidor DNS de la xarxa. Resol els noms de la pràctica (asix.local)
# i reenvia la resta a Internet. L'executa l'entrypoint abans d'arrencar dnsmasq.
set -e

# dnsmasq no llegeix /etc/dnsmasq.d si no l'arrenca el servei del sistema: el command del
# contenidor li passa aquest fitxer amb --conf-file
cat > /etc/dnsmasq.d/p00.conf <<'EOF'
# Només escolta a la seva adreça de la intranet
listen-address=10.213.2.53
listen-address=127.0.0.1
bind-interfaces

# No fa servir el resolv.conf del contenidor: reenvia a aquests servidors públics
no-resolv
no-hosts
server=1.1.1.1
server=8.8.8.8
cache-size=500

# Domini de la pràctica: els noms d'asix.local no es reenvien a Internet
domain=asix.local
local=/asix.local/

# Registres (nom curt i nom complet; un alias per servei)
host-record=r-n06.asix.local,r.asix.local,router.asix.local,10.213.2.254
host-record=w-n06.asix.local,web.asix.local,www.asix.local,10.213.1.10
host-record=f-n06.asix.local,ftp.asix.local,10.213.1.11
host-record=s-n06.asix.local,ssh.asix.local,10.213.1.12
host-record=b-n06.asix.local,bd.asix.local,db.asix.local,10.213.2.10
host-record=mon-n06.asix.local,monitor.asix.local,10.213.2.20
host-record=dns-n06.asix.local,dns.asix.local,10.213.2.53
host-record=dhcp-n06.asix.local,dhcp.asix.local,10.213.2.67

# Registre de les consultes (surt per docker logs)
log-queries
EOF

dnsmasq --test --conf-file=/etc/dnsmasq.d/p00.conf
echo "[dns] configuració vàlida"
