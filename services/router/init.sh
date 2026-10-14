#!/bin/bash
# Router R-NCC: enrutament entre DMZ, Intranet i NAT + firewall + port-forwarding.
set -e

DMZ_NET=10.213.1.; INT_NET=10.213.2.; NAT_NET=10.213.3.
W_IP=10.213.1.10; F_IP=10.213.1.11; S_IP=10.213.1.12
B_IP=10.213.2.10; DNS_IP=10.213.2.53

iface_of() { ip -o -4 addr show | awk -v p="$1" 'index($4,p)==1 {print $2; exit}'; }
IF_DMZ=$(iface_of $DMZ_NET); IF_INT=$(iface_of $INT_NET); IF_NAT=$(iface_of $NAT_NET)
echo "[router] DMZ=$IF_DMZ INTRANET=$IF_INT NAT=$IF_NAT"

# Sortida a Internet pel gateway de la xarxa NAT
ip route replace default via 10.213.3.1

iptables -F; iptables -t nat -F; iptables -X
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP

# --- FORWARD (política per defecte: DROP) ---
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# Intranet -> qualsevol destí (DMZ i Internet)
iptables -A FORWARD -i "$IF_INT" -j ACCEPT
# DMZ -> BBDD (MySQL) i DNS de la intranet. La resta de la intranet queda bloquejada.
iptables -A FORWARD -i "$IF_DMZ" -d $B_IP   -p tcp --dport 3306 -j ACCEPT
iptables -A FORWARD -i "$IF_DMZ" -d $DNS_IP -p udp --dport 53   -j ACCEPT
iptables -A FORWARD -i "$IF_DMZ" -d $DNS_IP -p tcp --dport 53   -j ACCEPT
# DMZ -> Internet (actualitzacions)
iptables -A FORWARD -i "$IF_DMZ" -o "$IF_NAT" -j ACCEPT
# Internet -> serveis publicats a la DMZ
iptables -A FORWARD -i "$IF_NAT" -o "$IF_DMZ" -d $W_IP -p tcp -m multiport --dports 80,443 -j ACCEPT
iptables -A FORWARD -i "$IF_NAT" -o "$IF_DMZ" -d $F_IP -p tcp --dport 21 -j ACCEPT
iptables -A FORWARD -i "$IF_NAT" -o "$IF_DMZ" -d $F_IP -p tcp --dport 30000:30009 -j ACCEPT
iptables -A FORWARD -i "$IF_NAT" -o "$IF_DMZ" -d $S_IP -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "FW-DROP: "

# --- NAT ---
iptables -t nat -A PREROUTING -i "$IF_NAT" -p tcp --dport 80   -j DNAT --to-destination $W_IP:80
iptables -t nat -A PREROUTING -i "$IF_NAT" -p tcp --dport 443  -j DNAT --to-destination $W_IP:443
iptables -t nat -A PREROUTING -i "$IF_NAT" -p tcp --dport 21   -j DNAT --to-destination $F_IP:21
iptables -t nat -A PREROUTING -i "$IF_NAT" -p tcp --dport 30000:30009 -j DNAT --to-destination $F_IP
iptables -t nat -A PREROUTING -i "$IF_NAT" -p tcp --dport 2222 -j DNAT --to-destination $S_IP:22
iptables -t nat -A POSTROUTING -o "$IF_NAT" -j MASQUERADE

echo "[router] firewall i NAT aplicats"
