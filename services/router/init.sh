#!/bin/bash
# Router R-NCC: enrutament entre DMZ, Intranet i NAT, sortida a Internet i firewall.
# Sprint 1: preparat i validat. Es desplega i es prova al sprint 2.
# Les regles cap a la BBDD i el DNS i el DNAT s'afegeixen amb cada servei.
set -e

DMZ_NET=10.213.1.; INT_NET=10.213.2.; NAT_NET=10.213.3.

# Les interfícies es detecten pel prefix de la seva adreça (eth0, eth1... no són fixes)
iface_of() { ip -o -4 addr show | awk -v p="$1" 'index($4,p)==1 {print $2; exit}'; }
IF_DMZ=$(iface_of $DMZ_NET); IF_INT=$(iface_of $INT_NET); IF_NAT=$(iface_of $NAT_NET)
echo "[router] DMZ=$IF_DMZ INTRANET=$IF_INT NAT=$IF_NAT"

# Sortida a Internet pel gateway de la xarxa NAT
ip route replace default via 10.213.3.1
# Clients d'Isard (xarxa itb 6): hi arriben a través de l'equip dels serveis, que és
# l'adreça .1 de la intranet (vegeu scripts/xarxa-clients.sh)
ip route replace 192.168.50.0/24 via 10.213.2.1

# --- Política per defecte ---
iptables -F; iptables -t nat -F; iptables -X
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP

# --- FORWARD (política per defecte: DROP) ---
# 1. Respostes de connexions ja establertes
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# 2. Intranet -> qualsevol destí (DMZ i Internet)
iptables -A FORWARD -i "$IF_INT" -j ACCEPT
# 3. DMZ -> Internet (actualitzacions)
iptables -A FORWARD -i "$IF_DMZ" -o "$IF_NAT" -j ACCEPT
# 4. SSH (port 2222): de fora cap al servidor S-N06 de la DMZ (només aquest port i aquest destí)
iptables -A FORWARD -i "$IF_NAT" -o "$IF_DMZ" -p tcp -d 10.213.1.12 --dport 2222 -j ACCEPT
# 5. DMZ -> BBDD (només MySQL): la web consulta la base de dades
iptables -A FORWARD -i "$IF_DMZ" -o "$IF_INT" -p tcp -d 10.213.2.10 --dport 3306 -j ACCEPT
# 6. DMZ -> DNS (només el port 53): resolució de noms
iptables -A FORWARD -i "$IF_DMZ" -o "$IF_INT" -p udp -d 10.213.2.53 --dport 53 -j ACCEPT
iptables -A FORWARD -i "$IF_DMZ" -o "$IF_INT" -p tcp -d 10.213.2.53 --dport 53 -j ACCEPT
# 7. Web (80 i 443): de fora cap a W-N06
iptables -A FORWARD -i "$IF_NAT" -o "$IF_DMZ" -p tcp -d 10.213.1.10 -m multiport --dports 80,443 -j ACCEPT
# 8. Tot el que no coincideix es registra (5 per minut) i es descarta per la política
iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "FW-DROP: "

# --- DNAT: el port 2222 publicat al router es reenvia al servidor SSH de la DMZ ---
iptables -t nat -A PREROUTING -i "$IF_NAT" -p tcp --dport 2222 -j DNAT --to-destination 10.213.1.12:2222

iptables -t nat -A PREROUTING -i "$IF_NAT" -p tcp --dport 80  -j DNAT --to-destination 10.213.1.10:80
iptables -t nat -A PREROUTING -i "$IF_NAT" -p tcp --dport 443 -j DNAT --to-destination 10.213.1.10:443

# El servidor SSH i la web responen sempre al router (si no, la resposta sortiria per una altra interfície)
iptables -t nat -A POSTROUTING -o "$IF_DMZ" -p tcp -d 10.213.1.12 --dport 2222 -j MASQUERADE
iptables -t nat -A POSTROUTING -o "$IF_DMZ" -p tcp -d 10.213.1.10 -m multiport --dports 80,443 -j MASQUERADE

# --- NAT: sortida a Internet amb l'adreça del router ---
iptables -t nat -A POSTROUTING -o "$IF_NAT" -j MASQUERADE

echo "[router] forwarding, firewall i NAT aplicats"