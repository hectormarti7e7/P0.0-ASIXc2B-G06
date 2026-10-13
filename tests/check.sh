#!/usr/bin/env bash
# Joc de proves automàtic. Executa'l després del desplegament: ./tests/check.sh
cd "$(dirname "$0")/.."
[ -f .env ] && { set -a; . ./.env; set +a; }
NCC="${NCC:-N01}"; PC="PC-L-${NCC}"; FAIL=0
U=bchecker; P=bchecker121

t() { local d="$1"; shift
  if "$@" >/dev/null 2>&1; then printf '[ OK ] %s\n' "$d"; else printf '[FAIL] %s\n' "$d"; FAIL=1; fi; }
px() { docker exec "$PC" bash -c "$1"; }

echo "== Xarxa i router =="
t "El client veu el router (ping R-$NCC)"       px "ping -c1 -W2 R-$NCC"
t "Sortida a Internet a través del router"      px "curl -fsI --max-time 8 https://example.com"
t "Traceroute passa pel router"                 px "traceroute -n -m2 1.1.1.1 | grep -q 172.20.2.254"

echo "== DNS / DHCP =="
t "DNS resol R-$NCC"                            px "dig +short @172.20.2.53 R-$NCC | grep -q 172.20.2.254"
t "DNS resol R (alias del router)"              px "dig +short @172.20.2.53 R | grep -q 172.20.2.254"
t "DNS resol W-$NCC i B-$NCC"                   px "dig +short W-$NCC | grep -q 172.20.1.10 && dig +short B-$NCC | grep -q 172.20.2.10"
t "DHCP respon a un DISCOVER"                   px "nmap --script broadcast-dhcp-discover -e eth0 2>&1 | grep -q 'DHCPOFFER'"

echo "== Serveis =="
t "SSH bchecker a W, F, B, S, R" px "for h in W F B S R; do sshpass -p $P ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 $U@\$h-$NCC hostname || exit 1; done"
t "MySQL: bchecker consulta la taula carregada" px "mysql -h B-$NCC -u$U -p$P -N -e 'select count(*) from equipaments.equipaments_educacio' | awk '\$1>0{ok=1} END{exit !ok}'"
t "FTP: login bchecker i llistat"               px "curl -fs --user $U:$P ftp://F-$NCC/ | grep -q LLEGEIX"
t "Web des de la intranet (/health)"            px "curl -fs http://W-$NCC/health | grep -q ok"
t "Web des del host a través del router"        curl -fs -u $U:$P "http://localhost:${HTTP_PORT:-80}/" 
t "Web: la pàgina mostra la taula"              bash -c "curl -fs -u $U:$P http://localhost:${HTTP_PORT:-80}/ | grep -q equipaments_educacio"
t "Web exigeix autenticació"                    bash -c "[ \"\$(curl -s -o /dev/null -w '%{http_code}' http://localhost:${HTTP_PORT:-80}/)\" = 401 ]"

echo "== Firewall (el que ha de quedar bloquejat) =="
t "DMZ -> BBDD 3306 permès"                     docker exec "W-$NCC" bash -c "timeout 4 bash -c '</dev/tcp/172.20.2.10/3306'"
t "DMZ -> SSH de la intranet bloquejat"         docker exec "W-$NCC" bash -c "! timeout 4 bash -c '</dev/tcp/172.20.2.10/22'"
t "Intranet -> DMZ permès (SSH a W)"            px "timeout 4 bash -c '</dev/tcp/172.20.1.10/22'"

echo
[ $FAIL = 0 ] && echo "TOTES LES PROVES OK" || echo "HI HA PROVES FALLIDES"
exit $FAIL
