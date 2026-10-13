# 4. Joc de proves

Automàtic: `./tests/check.sh` (també s'executa a `./deploy.sh up`).

| # | Prova | Resultat esperat |
|---|---|---|
| 1 | `ping R-NCC` des del client | respon |
| 2 | `curl https://example.com` des del client | surt a Internet pel router |
| 3 | `traceroute` | el primer salt és 172.20.2.254 |
| 4 | `dig R-NCC` i `dig R` | 172.20.2.254 |
| 5 | `nmap --script broadcast-dhcp-discover` | el servidor DHCP respon amb OFFER |
| 6 | SSH `bchecker` a W, F, B, S, R | entra |
| 7 | `select count(*) from equipaments_educacio` | > 0 |
| 8 | FTP `bchecker` | llista `LLEGEIX.txt` |
| 9 | Web des del host | mostra la taula; sense credencials → 401 |
| 10 | DMZ → BBDD 3306 | permès |
| 11 | DMZ → SSH de la intranet | **bloquejat** |
| 12 | Intranet → DMZ | permès |

## Proves manuals recomanades
- `docker stop B-N01` i comprovar que `/health` retorna 503 i que el monitor ho detecta.
- `docker compose down && ./deploy.sh up`: les dades de la BBDD es conserven (volum).
- `docker exec R-N01 iptables -L FORWARD -n -v` per veure els comptadors del firewall.
