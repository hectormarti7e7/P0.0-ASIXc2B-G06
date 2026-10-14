# 3. Configuració dels serveis (administrador)

Tota la configuració és fitxers del repositori; res es configura a mà dins dels contenidors.

| Servei | Fitxers | Què fa |
|---|---|---|
| Imatge base | `images/base/Dockerfile`, `entrypoint.sh` | Ubuntu 22.04 + sshd + usuari `bchecker`. L'entrypoint fixa el gateway al router, el DNS, executa `/opt/init.sh` del servei i arrenca sshd. |
| Router R-NCC | `services/router/init.sh` | `ip_forward`, regles `iptables` (FORWARD DROP), DNAT cap a la DMZ i MASQUERADE cap a NAT. |
| DNS | `services/dns/dnsmasq.conf.tpl` | Resol R-NCC i R (router) i la resta d'equips (`*.asix.local`); reenvia a 1.1.1.1 / 9.9.9.9. |
| DHCP | `services/dhcp/dnsmasq.conf.tpl` | Rang 10.213.2.100-200, gateway = router, DNS = DNS-NCC. |
| BBDD B-NCC | `services/db/*` | MySQL 8, base `equipaments`, usuaris `bchecker` (tot) i `webapp` (només lectura). `load_csv.py` descarrega el CSV i crea la taula `equipaments_educacio` a partir de la capçalera. |
| Web W-NCC | `services/web/*` | nginx (80/443, cert autosignat) → gunicorn → Flask. Mostra les taules (`/`, `/t/<taula>`, `/api/<taula>`). Autenticació bàsica bchecker. |
| FTP F-NCC | `services/ftp/*` | vsftpd amb usuari `bchecker`, mode passiu 30000-30009, volum persistent. |
| SSH S-NCC | `services/ssh/init.sh` | sshd amb `AllowUsers bchecker`, `MaxAuthTries 3`, `LogLevel VERBOSE`. |
| Monitor | `services/monitor/*` | Uptime Kuma a la intranet, amb ruta pel router. |

## Notes
- **Variables**: `NCC` a `.env` canvia tots els noms (R-N02, W-N02...). Les IP són fixes a `docker-compose.yml`.
- **Persistència**: volums `db-data`, `ftp-data`, `kuma-data`.
- **Usuari bchecker**: Linux (tots els contenidors amb sshd), MySQL, FTP, web (auth bàsica) i monitor (administrador).
- **Seguretat**: les contrasenyes són les imposades per la pràctica; en producció s'haurien de moure a *secrets* i canviar-se.
