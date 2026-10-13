# Monitor de xarxes: Uptime Kuma amb ruta per defecte pel router de la pràctica.
FROM louislam/uptime-kuma:1
RUN apt-get update && apt-get install -y --no-install-recommends iproute2 iputils-ping \
 && rm -rf /var/lib/apt/lists/*
COPY entrypoint.sh /route-entrypoint.sh
RUN chmod +x /route-entrypoint.sh
ENTRYPOINT ["/route-entrypoint.sh"]
CMD ["node", "server/server.js"]
