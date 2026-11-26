#!/usr/bin/env bash
# Comprovacions automàtiques de la infraestructura P0.0 (equip N06).
# Ús: ./scripts/comprova.sh   (des de l'arrel del repositori, a l'host de serveis)
# Mostra PASS o FAIL per a cada prova i acaba amb codi 1 si alguna falla.

cd "$(dirname "$0")/.." || exit 1
[ -f .env ] && set -a && . ./.env && set +a

APP_USER="${APP_USER:-bchecker}"
APP_PASS="${APP_PASS:-bchecker121}"
FALLS=0

prova() {  # prova "descripció" ordre...
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then
        echo "PASS  $desc"
    else
        echo "FAIL  $desc"; FALLS=$((FALLS + 1))
    fi
}

codi_http() {  # codi_http esperat curl-args...
    local esperat="$1"; shift
    [ "$(curl -sk -o /dev/null -w '%{http_code}' --max-time 10 "$@")" = "$esperat" ]
}

# Contenidors en marxa
for c in R-N06 W-N06 F-N06 S-N06 B-N06 MON-N06 DNS-N06 DHCP-N06; do
    prova "Contenidor $c en marxa" \
        sh -c "[ \"\$(docker inspect -f '{{.State.Running}}' $c)\" = true ]"
done

# Web
prova "HTTP redirigeix a HTTPS (301)"   codi_http 301 http://localhost/
prova "HTTPS sense credencials (401)"   codi_http 401 https://localhost/
prova "HTTPS contrasenya incorrecta (401)" \
    codi_http 401 -u "$APP_USER:contrasenya-incorrecta" https://localhost/
prova "HTTPS amb credencials (200)"     codi_http 200 -u "$APP_USER:$APP_PASS" https://localhost/
prova "/health sense credencials (200)" codi_http 200 https://localhost/health

# DNS: el nom del router ha de resoldre a 10.213.2.254
prova "DNS: r-n06.asix.local -> 10.213.2.254" \
    sh -c "docker exec DNS-N06 dig +short @127.0.0.1 r-n06.asix.local | grep -qx 10.213.2.254"

# Base de dades: hi ha almenys una taula d'usuari amb dades (no és el recompte exacte)
prova "BD: hi ha taules d'usuari" \
    sh -c "[ \"\$(docker exec B-N06 mysql -ubchecker -pbchecker121 -N -e \"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema NOT IN ('mysql','sys','information_schema','performance_schema')\")\" -gt 0 ]"

# SSH: la contrasenya ha d'estar desactivada a S-N06
prova "SSH: passwordauthentication no" \
    sh -c "docker exec S-N06 sshd -T | grep -qx 'passwordauthentication no'"
prova "SSH: permitrootlogin no" \
    sh -c "docker exec S-N06 sshd -T | grep -qx 'permitrootlogin no'"

echo
if [ "$FALLS" -eq 0 ]; then
    echo "Totes les proves han passat."
else
    echo "Proves fallides: $FALLS"
    exit 1
fi
