#!/bin/bash
# W-NCC: prepara nginx (certificat autosignat i configuració) i l'arrenca.
# gunicorn (l'aplicació Flask) l'arrenca el command del contenidor.
set -e

CRT=/etc/ssl/certs/w-n06.crt
KEY=/etc/ssl/private/w-n06.key

# Certificat autosignat (el navegador avisarà; en producció seria d'una CA)
if [ ! -s "$CRT" ]; then
  openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
    -subj "/C=ES/O=ASIX G06/CN=W-N06" -keyout "$KEY" -out "$CRT" 2>/dev/null
  chmod 600 "$KEY"
fi

rm -f /etc/nginx/sites-enabled/default
cp /opt/nginx.conf /etc/nginx/conf.d/p00.conf
nginx -t
nginx
echo "[web] nginx arrencat (80 -> 443 -> Flask 127.0.0.1:5000)"
