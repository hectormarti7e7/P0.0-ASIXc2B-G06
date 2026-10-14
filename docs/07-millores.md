# 7. Propostes de millora de l'últim MVP

| Proposta | Estat | Com encaixa amb Docker |
|---|---|---|
| Script de desplegament automatitzat | **Fet** | `deploy.sh` + `docker-compose.yml` |
| Segmentar la BBDD (relacions 1-m i n-m) | Pendent | Normalitzar `equipaments_educacio` en taules (districte, barri, tipus...) amb un script SQL addicional al *loader* |
| CRUD amb API REST (Flask) | Pendent | Ampliar `services/web/app/app.py` amb POST/PUT/DELETE (cal un usuari MySQL amb escriptura) |
| Connexió amb DNS i domini públics | Pendent | Registrar un domini i apuntar-lo a la IP pública; el router ja fa el port-forwarding |
| Certificats i domini públic per FTP i Web | Parcial | Web té cert autosignat; substituir per Let's Encrypt (certbot) i afegir FTPS a vsftpd |
| Honeypot a la DMZ | Pendent | Nou servei `cowrie` a la xarxa `dmz` (ip 10.213.1.13) i regla de DNAT |
| SSH amb port knocking i fail2ban | Pendent | `knockd` + `fail2ban` al contenidor S-NCC (cal `iptables` i NET_ADMIN, ja concedit) |
