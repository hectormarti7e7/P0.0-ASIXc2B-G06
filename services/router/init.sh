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
# 4. Tot el que no coincideix es registra (5 per minut) i es descarta per la política
iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "FW-DROP: "

# --- NAT: sortida a Internet amb l'adreça del router ---
iptables -t nat -A POSTROUTING -o "$IF_NAT" -j MASQUERADE

echo "[router] forwarding, firewall i NAT aplicats"