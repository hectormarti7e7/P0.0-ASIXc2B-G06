#!/bin/bash
# W-NCC: certificat autosignat, nginx com a proxy i aplicació Flask amb gunicorn.
set -e
mkdir -p /etc/nginx/ssl
if [ ! -f /etc/nginx/ssl/web.crt ]; then
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -subj "/CN=W-${NCC:-N01}.asix.local" \
    -keyout /etc/nginx/ssl/web.key -out /etc/nginx/ssl/web.crt 2>/dev/null
fi
rm -f /etc/nginx/sites-enabled/default
cd /srv/app
gunicorn --daemon --user www-data -b 127.0.0.1:8000 -w 2 \
  --access-logfile /var/log/gunicorn.log --error-logfile /var/log/gunicorn.err app:app
