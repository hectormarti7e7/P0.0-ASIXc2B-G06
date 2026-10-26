# Arquitectura de la infraestructura

| | |
|---|---|
| **Projecte** | P0.0 · Desplegament d'infraestructura |
| **Mòdul** | 0379 · Projecte intermodular (ASIX) |
| **Equip** | G06 (ASIXc2B) · identificador N06 |
| **Autors** | Josep Pérez, Hèctor Martí |
| **Versió** | 1.1 · 26/10/2026 · Sprint 1 |

## Índex
1. [Objectiu i abast](#1-objectiu-i-abast)
2. [Visió general](#2-visió-general)
3. [Components](#3-components)
4. [Xarxes i segmentació](#4-xarxes-i-segmentació)
5. [Adreçament IP](#5-adreçament-ip)
6. [Política del firewall](#6-política-del-firewall)
7. [Principis de disseny](#7-principis-de-disseny)
8. [Limitacions conegudes](#8-limitacions-conegudes)
9. [Historial de versions](#9-historial-de-versions)

## 1. Objectiu i abast
Aquest document descriu l'arquitectura de la infraestructura multicapa de la pràctica P0.0: quins components hi ha, com es connecten i per què s'han dissenyat així. Cada servei s'executa en un **contenidor Docker** en lloc d'una màquina virtual per servei. La justificació tecnològica és a l'[estudi previ](09-estudi-previ.md).

## 2. Visió general
El router és un contenidor Linux amb `ip_forward` i `iptables`, connectat a tres xarxes (DMZ, Intranet i NAT). Tot el trànsit entre xarxes passa pel router.

![Arquitectura de la infraestructura](img/arquitectura-N06.svg)

*Figura 1. Arquitectura de la infraestructura (equip N06).*

## 3. Components
| Component | Nom | Tecnologia | Xarxa |
|---|---|---|---|
| Router i firewall | R-N06 | Linux, `iptables` | NAT, DMZ i Intranet |
| Web | W-N06 | nginx i Flask | DMZ |
| FTP | F-N06 | vsftpd | DMZ |
| SSH (bastió) | S-N06 | OpenSSH | DMZ |
| Base de dades | B-N06 | MySQL 8 | Intranet |
| DNS | DNS-N06 | dnsmasq | Intranet |
| DHCP | DHCP-N06 | dnsmasq | Intranet |
| Monitor de xarxa | MON-N06 | Uptime Kuma | Intranet |
| Client Linux | PC-L-N06 | Ubuntu | Intranet |
| Client Windows | PC-W-N06 | Windows (màquina virtual) | Intranet |

## 4. Xarxes i segmentació
| Xarxa | Subxarxa | Funció |
|---|---|---|
| NAT | 10.213.3.0/24 | Sortida a Internet i entrada pel port-forwarding del router |
| DMZ | 10.213.1.0/24 | Serveis exposats a Internet (web, FTP i SSH) |
| Intranet | 10.213.2.0/24 | Serveis interns (BBDD, DNS, DHCP, monitor i clients) |

## 5. Adreçament IP
Totes les adreces són fixes i es defineixen a `docker-compose.yml`. En cada xarxa, l'adreça `.1` la reserva Docker com a *gateway* intern i no l'usa cap equip de la pràctica.

| Equip | Hostname | Xarxa | Adreça IP |
|---|---|---|---|
| Router | R-N06 (àlies `R`) | NAT / DMZ / Intranet | 10.213.3.2 / 10.213.1.254 / 10.213.2.254 |
| Web | W-N06 | DMZ | 10.213.1.10 |
| FTP | F-N06 | DMZ | 10.213.1.11 |
| SSH (bastió) | S-N06 | DMZ | 10.213.1.12 |
| Base de dades | B-N06 | Intranet | 10.213.2.10 |
| Càrrega de dades (temporal) | LOADER-N06 | Intranet | 10.213.2.11 |
| Monitor de xarxa | MON-N06 | Intranet | 10.213.2.20 |
| DNS | DNS-N06 | Intranet | 10.213.2.53 |
| Client Linux | PC-L-N06 | Intranet | 10.213.2.50 |
| Client Windows | PC-W-N06 | Intranet | 10.213.2.60 |
| DHCP | DHCP-N06 | Intranet | 10.213.2.67 (reparteix el rang 10.213.2.100 a 10.213.2.200) |

El *gateway* per defecte dels equips de la DMZ és `10.213.1.254` i el dels equips de la intranet és `10.213.2.254`, de manera que tot el trànsit entre xarxes passa pel router.

## 6. Política del firewall
El router aplica la política `FORWARD DROP`: tot el trànsit que ha de travessar el router queda bloquejat, excepte el que es permet explícitament. El trànsit que entra o surt del propi router (`INPUT` i `OUTPUT`) no es filtra.

### 6.1 Regles permeses
| # | Origen | Destí | Protocol i port | Motiu |
|---|---|---|---|---|
| 1 | Qualsevol | Qualsevol | Respostes de connexions ja establertes | Permet que tornin les respostes |
| 2 | Intranet | DMZ i Internet | Tot | La intranet és de confiança |
| 3 | DMZ | BBDD (B-N06) | TCP 3306 | La web consulta la base de dades |
| 4 | DMZ | DNS (DNS-N06) | UDP i TCP 53 | Resolució de noms |
| 5 | DMZ | Internet | Tot | Actualitzacions |
| 6 | Internet | Web (W-N06) | TCP 80 i 443 | Servei públic |
| 7 | Internet | FTP (F-N06) | TCP 21 i 30000-30009 | FTP actiu i mode passiu |
| 8 | Internet | SSH (S-N06) | TCP 22 | Accés d'administració pel bastió |

Tot el que no coincideix amb cap d'aquestes regles es bloqueja. Els paquets descartats es registren (límit de 5 per minut) amb el prefix `FW-DROP:`.

### 6.2 Trànsit bloquejat
| Origen | Destí | Resultat |
|---|---|---|
| DMZ | Resta de la intranet (excepte BBDD per 3306 i DNS per 53) | Bloquejat |
| Internet | Intranet | Bloquejat |
| Internet | Serveis de la DMZ per ports no publicats | Bloquejat |

Així, si un servei exposat a Internet es veiés compromès, no podria arribar a la resta de la xarxa interna.

### 6.3 Reenviament de ports (NAT)
| Port d'entrada (host) | Destí | Port destí |
|---|---|---|
| 80 i 443 | W-N06 (10.213.1.10) | 80 i 443 |
| 21 i 30000-30009 | F-N06 (10.213.1.11) | 21 i 30000-30009 |
| 2222 | S-N06 (10.213.1.12) | 22 |

La sortida a Internet dels equips interns es fa amb emmascarament (`MASQUERADE`) a la interfície de la xarxa NAT.

## 7. Principis de disseny
- **Segmentació:** els serveis exposats viuen a la DMZ i només poden iniciar connexions cap a la BBDD i el DNS.
- **Punt únic de control:** tots els contenidors tenen el router com a *gateway*, de manera que el firewall veu tot el trànsit entre xarxes.
- **Reproductibilitat:** la infraestructura es descriu amb fitxers del repositori i es desplega amb una sola comanda.
- **Mínim privilegi:** el firewall segueix la política `FORWARD DROP` i només s'obre el que cal.

## 8. Limitacions conegudes
- Els contenidors comparteixen el nucli del sistema amfitrió, de manera que l'aïllament és més feble que amb màquines virtuals.
- El client Windows no pot ser un contenidor Linux i s'executa com a màquina virtual.

## 9. Historial de versions
| Versió | Data | Canvis |
|---|---|---|
| 1.0 | 22/10/2026 | Primera versió: components, xarxes i diagrama |
| 1.1 | 26/10/2026 | Adreçament IP i política del firewall (Hèctor Martí) |
