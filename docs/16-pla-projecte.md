# Pla del projecte

| | |
|---|---|
| **Projecte** | P0.0 · Desplegament d'infraestructura |
| **Mòdul** | 0379 · Projecte intermodular (ASIX) |
| **Equip** | G06 (ASIXc2B) · identificador N06 |
| **Autor** | Josep Pérez |
| **Versió** | 1.1 · 16/11/2026 · Sprint 2 |

## Índex
1. [Objectiu i abast](#1-objectiu-i-abast)
2. [Fases i sprints](#2-fases-i-sprints)
3. [Tasques i responsables](#3-tasques-i-responsables)
4. [Recursos](#4-recursos)
5. [Dedicació](#5-dedicació)
6. [Riscos](#6-riscos)
7. [Seguiment](#7-seguiment)
8. [Historial de versions](#8-historial-de-versions)

## 1. Objectiu i abast
Aquest document recull com s'organitza el projecte: les fases, qui fa cada tasca, els recursos necessaris, la dedicació prevista i els riscos amb la seva mitigació. El projecte dura 6 setmanes, fins al 18/11/2026, repartides en 3 sprints quinzenals. Les dates i l'estat de cada tasca són a ProofHub, que és la font de referència.

## 2. Fases i sprints
| Fase | Sprint | Objectiu | Entregables |
|---|---|---|---|
| 1. Preparació | 1 | Base de la infraestructura i decisions tècniques | ProofHub i backlog, repositori, diagrama, estudis previs, imatge base, tres xarxes, router i firewall base, documentació inicial |
| 2. Serveis | 2 | Desplegar els serveis i els clients | BBDD amb el CSV carregat, web i aplicació de proves, SSH, DHCP, DNS, FTP, monitor, client Linux i client Windows |
| 3. Integració i tancament | 3 | Connectar els serveis, provar-los i documentar-los | Regles del firewall i reenviament de ports cap als serveis, proves de rendiment i disponibilitat, documentació per al client i per a l'administrador, defensa |

## 3. Tasques i responsables
### Sprint 1
| Tasca | Responsable |
|---|---|
| Crear el projecte a ProofHub, amb el backlog i els 3 sprints | Josep Pérez |
| Repositori GitHub, clau SSH, col·laboradors, branques i plantilla de PR | Hèctor Martí |
| Estudi previ: contenidors o màquines virtuals, MySQL o MariaDB | Josep Pérez |
| Estudi previ: nginx o Apache, Uptime Kuma o Zabbix, iptables o nftables | Hèctor Martí |
| Diagrama d'arquitectura | Josep Pérez |
| Taula d'adreçament i política de firewall | Hèctor Martí |
| Imatge base i `docker-compose` amb les 3 xarxes | Josep Pérez |
| Router R-N06: reenviament, NAT i firewall | Hèctor Martí |

### Sprint 2
| Tasca | Responsable |
|---|---|
| BBDD MySQL amb l'usuari `bchecker` | Josep Pérez |
| Client Linux (PC-L-N06) | Josep Pérez |
| Script de càrrega del CSV d'equipaments | Josep Pérez |
| Servidor SSH | Josep Pérez |
| Aplicació web Flask que mostra les taules | Josep Pérez |
| Servidor web nginx base | Hèctor Martí |
| DHCP de la intranet | Hèctor Martí |
| Monitor de xarxes (Uptime Kuma) amb sondes | Hèctor Martí |
| Client Windows | Hèctor Martí |
| DNS (ha de resoldre `R-N06` i `R`) i FTP | Per repartir |

### Sprint 3
| Tasca | Responsable |
|---|---|
| Regles del firewall (BBDD, DNS) i reenviament de ports | Per repartir |
| Proves de rendiment i disponibilitat | Per repartir |
| Documentació per al client i per a l'administrador | Per repartir |
| Preparació de la defensa | Josep Pérez i Hèctor Martí |

## 4. Recursos
| Tipus | Recurs |
|---|---|
| Persones | Josep Pérez i Hèctor Martí |
| Maquinari | Un servidor o equip Linux amb Docker (provat a Ubuntu 24) i virtualització per al client Windows |
| Programari d'infraestructura | Docker Engine 24 o superior, Docker Compose v2, `iptables` |
| Serveis | nginx i Flask amb gunicorn, MySQL 8.0, dnsmasq (DNS i DHCP), vsftpd, OpenSSH, Uptime Kuma |
| Gestió | ProofHub (tasques i hores), GitHub (codi i documentació) |
| Cost | Cap llicència de pagament. El client Windows depèn de la versió disponible per a l'avaluació |

## 5. Dedicació
L'enunciat fixa 5 hores setmanals per persona, és a dir, 10 hores per sprint.

| Sprint | Hores per persona | Hores de l'equip |
|---|---|---|
| 1 | 10 | 20 |
| 2 | 10 | 20 |
| 3 | 10 | 20 |
| **Total** | **30** | **60** |

## 6. Riscos
| Risc | Probabilitat | Impacte | Mitigació |
|---|---|---|---|
| Retard per la poca dedicació disponible (10 h per persona i sprint) | Alta | Alt | Tasques petites amb criteri de «feta» a ProofHub, prioritat als requisits de l'enunciat i revisió de l'estat a cada sessió |
| Conflicte entre el rang de les xarxes Docker i xarxes existents al servidor (ja va passar amb 172.20.0.0/16) | Mitjana | Mitjà | S'ha fixat 10.213.0.0/16; si torna a passar, es canvien les tres subxarxes del compose ([manual de desplegament](02-desplegament-client.md), apartat 8) |
| El client Windows no es pot executar com a contenidor Linux | Alta | Mitjà | Màquina virtual o, si el servidor té KVM, un contenidor Windows (projecte `dockur/windows`) |
| Pèrdua de configuració o de dades del servidor | Baixa | Alt | Tota la configuració és a GitHub i les dades de MySQL van a un volum Docker; la infraestructura es recrea amb `docker compose up -d --build` |
| Barreja de *backends* iptables i nftables a la mateixa màquina | Baixa | Mitjà | Mantenir iptables al router i no activar el *backend* nftables experimental de Docker ([estudi previ 11](11-estudi-previ-web-monitor-firewall.md), apartat 4) |
| Una actualització de MySQL a la 8.4 desactiva `mysql_native_password` | Baixa | Mitjà | Fixar MySQL 8.0 i revisar els usuaris abans d'actualitzar ([estudi previ 09](09-estudi-previ.md), apartat 9.3) |
| Credencials conegudes (`bchecker` / `bchecker121`, imposades per l'enunciat) | Alta | Baix | S'usen només en aquest entorn de pràctica, no es reutilitzen en cap altre sistema i la BBDD només és accessible des de la intranet i, pel port 3306, des de la DMZ |
| El CSV d'equipaments pot no estar en UTF-8 | Mitjana | Mitjà | Comprovar la codificació abans de carregar-lo i documentar la càrrega |
| Conflictes de Git entre els dos integrants | Mitjana | Baix | Una branca de vida curta per cada tasca de ProofHub i Pull Request cap a `main` ([control de versions](14-control-versions.md)) |

## 7. Seguiment
- **ProofHub:** cada tasca té responsable, data de venciment i criteri de «feta»; s'hi registren les hores treballades.
- **Diari de treball:** a cada sessió s'hi afegeix una nota amb el que s'ha fet i el que falla.
- **GitHub:** cada tasca de ProofHub té la seva branca i el seu Pull Request, i cada commit recull una sola part del treball.
- **Etiquetes:** el tancament de cada sprint es marca amb una etiqueta de Git (`sprint1`, `sprint2`...).

## 8. Historial de versions
| Versió | Data | Canvis |
|---|---|---|
| 1.0 | 15/11/2026 | Primera versió: fases, tasques, recursos, dedicació, riscos i seguiment |
| 1.1 | 16/11/2026 | Una branca per tasca de ProofHub en lloc d'una per persona |
