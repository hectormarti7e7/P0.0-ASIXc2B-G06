# Índex de la documentació

| | |
|---|---|
| **Projecte** | P0.0 · Desplegament d'infraestructura |
| **Equip** | G06 (ASIXc2B) · identificador N06 |

Tots els documents són en Markdown i es versionen amb el codi. La numeració no és correlativa: els antics documents 05 (càrrega del CSV), 10 (router i firewall) i 20 (pla de proves) s'han integrat als documents 03, 01 i 15.

## Documents disponibles
| Document | Contingut | Autor | Versió |
|---|---|---|---|
| [01 · Arquitectura](01-arquitectura.md) | Components, xarxes, adreçament IP, política del firewall i implementació del router | Josep Pérez i Hèctor Martí | 1.5 |
| [02 · Manual d'instal·lació i administració](02-desplegament-client.md) | Requisits, imatge base, xarxes, serveis, desplegament, operació, manteniment, incidències i comprovació | Josep Pérez | 2.0 |
| [03 · Base de dades MySQL i càrrega del CSV](03-bbdd-mysql.md) | Servidor MySQL, base de dades `equipaments`, usuari `bchecker`, proves i càrrega del CSV d'equipaments | Josep Pérez | 2.0 |
| [04 · Clients a Isard (itb 6)](04-clients-isard.md) | Màquines virtuals dels clients, connexió amb la intranet i proves | Josep Pérez | 1.2 |
| [06 · Aplicació web](06-aplicacio-web.md) | Aplicació Flask amb nginx (HTTPS) i autenticació (401), regles del router i proves | Josep Pérez | 1.2 |
| [07 · Servidor SSH](07-servidor-ssh.md) | Instal·lació, configuració, seguretat i proves (port 2222, només clau pública) | Josep Pérez | 1.0 |
| [09 · Estudi previ: contenidors i base de dades](09-estudi-previ.md) | Contenidors o màquines virtuals, MySQL o MariaDB | Josep Pérez | 16/10/2026 |
| [11 · Estudi previ: web, monitor i firewall](11-estudi-previ-web-monitor-firewall.md) | nginx o Apache, Uptime Kuma o Zabbix, iptables o nftables | Hèctor Martí | 26/10/2026 |
| [14 · Control de versions](14-control-versions.md) | Git i GitHub: clau SSH, comandes, branques i pujada a producció | Josep Pérez | 1.1 |
| [15 · Criteris de rendiment i disponibilitat, i pla de proves](15-criteris-rendiment-disponibilitat.md) | Objectius mesurables, com es mesuren i pla de proves amb el resultat de cada prova | Josep Pérez | 2.0 |
| [16 · Pla del projecte i prevenció de riscos](16-pla-projecte.md) | Fases, tasques, recursos, calendari, riscos tècnics i riscos laborals | Josep Pérez | 1.4 |

## Documents previstos
| Document | Sprint |
|---|---|
| DHCP, DNS, FTP i monitor de xarxa | 2 |
| Client Windows | 2 |
| Proves de rendiment i disponibilitat (resultats) | 2 i 3 |
| Documentació final per al client i per a l'administrador | 3 |

L'[estudi previ 11](11-estudi-previ-web-monitor-firewall.md) fa referència a dos documents que encara no són al repositori: la recopilació d'informació (`12-recopilacio-informacio.md`) i l'anàlisi de mercat (`13-analisi-mercat.md`).

## Imatges
Les figures i captures són a [img/](img/).
