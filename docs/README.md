# Índex de la documentació

| | |
|---|---|
| **Projecte** | P0.0 · Desplegament d'infraestructura |
| **Equip** | G06 (ASIXc2B) · identificador N06 |

Tots els documents són en Markdown i es versionen amb el codi. La numeració deixa lliures els números 06 a 08 per a la documentació dels serveis dels sprints 2 i 3.

## Documents disponibles
| Document | Contingut | Autor | Versió |
|---|---|---|---|
| [01 · Arquitectura](01-arquitectura.md) | Components, xarxes, adreçament IP i política del firewall | Josep Pérez i Hèctor Martí | 1.4 |
| [02 · Manual de desplegament (client)](02-desplegament-client.md) | Requisits, imatge base, xarxes i comprovació | Josep Pérez | 1.2 |
| [03 · Base de dades MySQL](03-bbdd-mysql.md) | Servidor MySQL, base de dades `equipaments`, usuari `bchecker` i proves | Josep Pérez | 1.0 |
| [04 · Clients a Isard (itb 6)](04-clients-isard.md) | Màquines virtuals dels clients, connexió amb la intranet i proves | Josep Pérez | 1.2 |
| [05 · Càrrega del CSV](05-carrega-csv.md) | Script de càrrega, origen de les dades, execució i verificació | Josep Pérez | 1.0 |
| [07 · Servidor SSH](07-servidor-ssh.md) | Instal·lació, configuració, seguretat i proves (port 2222, només clau pública) | Josep Pérez | 1.0 |
| [09 · Estudi previ: contenidors i base de dades](09-estudi-previ.md) | Contenidors o màquines virtuals, MySQL o MariaDB | Josep Pérez | 16/10/2026 |
| [10 · Router i firewall](10-router-firewall.md) | Funcionament, interfícies i regles del router | Hèctor Martí | 1.0 |
| [11 · Estudi previ: web, monitor i firewall](11-estudi-previ-web-monitor-firewall.md) | nginx o Apache, Uptime Kuma o Zabbix, iptables o nftables | Hèctor Martí | 26/10/2026 |
| [14 · Control de versions](14-control-versions.md) | Git i GitHub: clau SSH, comandes, branques i pujada a producció | Josep Pérez | 1.1 |
| [15 · Criteris de rendiment i disponibilitat](15-criteris-rendiment-disponibilitat.md) | Objectius mesurables i com es mesuren | Josep Pérez | 1.4 |
| [16 · Pla del projecte](16-pla-projecte.md) | Fases, tasques, recursos, calendari i riscos | Josep Pérez | 1.3 |

## Documents previstos
| Document | Sprint |
|---|---|
| Servidor web i aplicació que mostra les taules | 2 |
| DHCP, DNS, FTP i monitor de xarxa | 2 |
| Client Windows | 2 |
| Proves de rendiment i disponibilitat (resultats) | 2 i 3 |
| Documentació final per al client i per a l'administrador | 3 |

L'[estudi previ 11](11-estudi-previ-web-monitor-firewall.md) fa referència a dos documents que encara no són al repositori: la recopilació d'informació (`12-recopilacio-informacio.md`) i l'anàlisi de mercat (`13-analisi-mercat.md`).

## Imatges
Les figures i captures són a [img/](img/).
