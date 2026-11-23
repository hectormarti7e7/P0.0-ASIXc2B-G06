# Monitor de xarxa (MON-NCC): Uptime Kuma sobre la imatge oficial.
# S'hi afegeixen les eines de xarxa, l'usuari bchecker i un entrypoint que fixa el gateway
# (el router de la pràctica) i el DNS abans d'arrencar Uptime Kuma.
FROM louislam/uptime-kuma:1.23.16

# La imatge oficial es basa en Debian 10 (buster), que ja no té repositoris normals:
# s'usa l'arxiu històric (archive.debian.org) i es desactiva la caducitat dels índexs.
RUN sed -i 's|deb.debian.org|archive.debian.org|g; s|security.debian.org|archive.debian.org|g; /buster-updates/d' /etc/apt/sources.list \
 && apt-get -o Acquire::Check-Valid-Until=false update \
 && apt-get install -y --no-install-recommends \
      iproute2 iputils-ping dnsutils curl openssh-server sudo \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /run/sshd \
 && useradd -m -s /bin/bash -G sudo bchecker \
 && echo 'bchecker:bchecker121' | chpasswd

COPY monitor-entrypoint.sh /monitor-entrypoint.sh
RUN chmod +x /monitor-entrypoint.sh

WORKDIR /app
ENTRYPOINT ["/usr/bin/dumb-init", "--", "/monitor-entrypoint.sh"]
CMD ["node", "server/server.js"]
