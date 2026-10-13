# Imatge base comuna: Ubuntu + SSH + usuari bchecker. Cada servei hi afegeix paquets amb PKGS.
FROM ubuntu:22.04
ARG PKGS=""
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      openssh-server sudo iproute2 iptables iputils-ping dnsutils curl ca-certificates \
      nano procps gettext-base net-tools ${PKGS} \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /run/sshd \
 && useradd -m -s /bin/bash -G sudo bchecker \
 && echo 'bchecker:bchecker121' | chpasswd
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
