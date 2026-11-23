# Servidor DNS (DNS-N06)

| | |
|---|---|
| **Projecte** | P0.0 · Desplegament d'infraestructura |
| **Mòdul** | 0379 · Projecte intermodular (ASIX) |
| **Equip** | G06 (ASIXc2B) · identificador N06 |
| **Autors** | Hèctor Martí, Josep Pérez |
| **Versió** | 1.0 · 22/11/2026 · Sprint 2 |

## Índex
1. [Objectiu i abast](#1-objectiu-i-abast)
2. [Característiques](#2-característiques)
3. [Instal·lació i configuració](#3-installació-i-configuració)
4. [Seguretat](#4-seguretat)
5. [Comprovacions](#5-comprovacions)
6. [Resolució de problemes](#6-resolució-de-problemes)
7. [Historial de versions](#7-historial-de-versions)

## 1. Objectiu i abast
Aquest document descriu el servidor DNS `DNS-N06`: resol els noms dels equips de la pràctica (domini `asix.local`) i reenvia la resta de consultes a Internet.

## 2. Característiques
| Element | Valor |
|---|---|
| Contenidor | `DNS-N06`, imatge construïda sobre la imatge base amb `dnsmasq` |
| Xarxa i adreça | Intranet · 10.213.2.53 (gateway: el router, 10.213.2.254) |
| Programari | `dnsmasq`, en primer pla, amb el registre de consultes a `docker logs` |
| Domini | `asix.local` (no es reenvia mai a Internet) |
| Reenviament | 1.1.1.1 i 8.8.8.8 |
| Usuaris | Tots els contenidors de la pràctica (`DNS_SERVER` al `docker-compose.yml`) i els clients, que el poden consultar directament |

## 3. Instal·lació i configuració
S'arrenca amb la resta de la infraestructura (`docker compose up -d --build`); no cal instal·lar res a mà.

| Fitxer | Contingut |
|---|---|
| `services/dns/init.sh` | Escriu la configuració a `/etc/dnsmasq.d/p00.conf` i la valida amb `dnsmasq --test` abans d'arrencar. Si falla, el contenidor no arrenca |
| `docker-compose.yml` | Servei `dns`: adreça fixa, `command` amb `--conf-file`, `healthcheck` i la variable `DNS_SERVER=10.213.2.53` als altres serveis |
| `services/router/init.sh` | Regles `FORWARD` que deixen la DMZ consultar el DNS (UDP i TCP 53) |

**Important:** `dnsmasq` només llegeix `/etc/dnsmasq.d` si l'arrenca el servei del sistema. Com que al contenidor s'arrenca directament, el `command` li passa el fitxer amb `--conf-file=/etc/dnsmasq.d/p00.conf`. Sense això, ignora la configuració i reenvia tot a Internet sense resoldre els noms interns.

### 3.1 Registres
| Nom | Àlies | Adreça |
|---|---|---|
| `r-n06.asix.local` | `r`, `router` | 10.213.2.254 |
| `w-n06.asix.local` | `web`, `www` | 10.213.1.10 |
| `f-n06.asix.local` | `ftp` | 10.213.1.11 |
| `s-n06.asix.local` | `ssh` | 10.213.1.12 |
| `b-n06.asix.local` | `bd`, `db` | 10.213.2.10 |
| `mon-n06.asix.local` | `monitor` | 10.213.2.20 |
| `dns-n06.asix.local` | `dns` | 10.213.2.53 |
| `dhcp-n06.asix.local` | `dhcp` | 10.213.2.67 |

Els contenidors porten `search asix.local` al `resolv.conf`, així que poden usar el nom curt (per exemple, `b-n06`).

**Requisit de l'enunciat:** el DNS ha de resoldre `R-NCC` i `R` pel router. Es resolen amb `R-N06` (`r-n06.asix.local`) i `R` (`r.asix.local`) i donen l'adreça del router a la intranet, 10.213.2.254. Els noms de domini no distingeixen majúscules de minúscules.

### 3.2 Camí del trànsit
- **Intranet:** els equips consulten el DNS directament (la mateixa xarxa).
- **DMZ:** consulten el DNS a través del router, per la regla `FORWARD` DMZ → 10.213.2.53 al port 53.
- **Clients (`itb 6`):** hi arriben per l'equip dels serveis, igual que a la base de dades ([document 04](04-clients-isard.md)).
- **Internet:** el DNS reenvia a 1.1.1.1 i 8.8.8.8 a través del router, que ja deixa sortir la intranet.

## 4. Seguretat
| Mesura | Efecte |
|---|---|
| `listen-address` i `bind-interfaces` | Només escolta a 10.213.2.53 i a 127.0.0.1 |
| `local=/asix.local/` | Les consultes del domini intern no surten mai a Internet |
| `no-resolv` i `no-hosts` | Ignora el `resolv.conf` i el `/etc/hosts` del contenidor: només respon el que diu la configuració |
| Firewall | Des de la DMZ només s'arriba al port 53 d'aquest equip; Internet no hi arriba |
| Validació | `dnsmasq --test` abans d'arrencar |

## 5. Comprovacions
Resultats del 22/11/2026.

### 5.1 Des del client Linux (`PC-L-N06`)
| # | Ordre | Esperat | Obtingut |
|---|---|---|---|
| 1 | `dig +short @10.213.2.53 w-n06.asix.local` | Adreça de la web | `10.213.1.10` |
| 2 | `dig +short @10.213.2.53 bd.asix.local` | Adreça de la BBDD (àlies) | `10.213.2.10` |
| 3 | `dig +short @10.213.2.53 example.com` | Una adreça pública (reenviament) | `104.20.23.154` |
| 3b | `dig +short @10.213.2.53 R-N06.asix.local` i `dig +short @10.213.2.53 R.asix.local` | Adreça del router (requisit de l'enunciat) | `10.213.2.254` en tots dos |

### 5.2 Des dels contenidors
| # | Origen | Ordre | Obtingut |
|---|---|---|---|
| 4 | DMZ (`W-N06`) | `dig +short www.asix.local` | `10.213.1.10` |
| 5 | DMZ (`W-N06`) | `dig +short example.com` | `104.20.23.154` |
| 6 | Intranet (`B-N06`) | `dig +short ssh.asix.local` | `10.213.1.12` |
| 7 | DMZ (`W-N06`) | `dig nonexistent.asix.local` | `status: NXDOMAIN` |

La prova 7 comprova que un nom de `asix.local` que no existeix no es reenvia a Internet. Els logs confirmen la configuració carregada: `using nameserver 1.1.1.1#53` i `using only locally-known addresses for asix.local`.

## 6. Resolució de problemes
| Símptoma | Causa | Solució |
|---|---|---|
| Els noms interns no es resolen i `example.com` sí | `dnsmasq` no ha carregat la configuració (al log surt `using nameserver 127.0.0.11`) | Comprovar que el `command` porta `--conf-file=/etc/dnsmasq.d/p00.conf` i recrear: `docker compose up -d --force-recreate dns` |
| `dig` dins de `DNS-N06` no troba els noms interns | `dig` fa servir el DNS de Docker del contenidor, no `dnsmasq` | Consultar-lo explícitament: `dig @127.0.0.1 b-n06.asix.local` |
| Un contenidor de la DMZ no resol | Falta la regla del router DMZ → DNS | Comprovar `iptables -S FORWARD` al router (regla amb `--dport 53`) |
| He canviat `services/dns/init.sh` i no s'aplica | El fitxer va muntat al contenidor: `docker compose up` no el reinicia si només canvia el contingut | `docker compose up -d --force-recreate dns` |
| El servei no arrenca | Error a la configuració | `docker logs DNS-N06` mostra l'error de `dnsmasq --test` |

## 7. Historial de versions
| Versió | Data | Canvis |
|---|---|---|
| 1.0 | 22/11/2026 | Primera versió: dnsmasq, registres, regla DMZ → DNS i proves |
