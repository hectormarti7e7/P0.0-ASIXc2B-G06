# Servidor DHCP (DHCP-N06)

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
4. [Seguretat i limitacions](#4-seguretat-i-limitacions)
5. [Comprovacions](#5-comprovacions)
6. [Resolució de problemes](#6-resolució-de-problemes)
7. [Historial de versions](#7-historial-de-versions)

## 1. Objectiu i abast
Aquest document descriu el servidor DHCP `DHCP-N06`: reparteix adreces IP als equips de la intranet i els diu quin és el router i el servidor DNS.

## 2. Característiques
| Element | Valor |
|---|---|
| Contenidor | `DHCP-N06`, imatge construïda sobre la imatge base amb `dnsmasq` |
| Xarxa i adreça | Intranet · 10.213.2.67 (gateway: el router, 10.213.2.254) |
| Rang repartit | 10.213.2.100 a 10.213.2.200 (màscara 255.255.255.0) |
| Temps de cessió | 12 hores |
| Opcions que envia | Router `10.213.2.254`, DNS `10.213.2.53` ([document 08](08-servidor-dns.md)) i domini `asix.local` |
| Programari | `dnsmasq` només com a DHCP (`port=0` desactiva la part de DNS) |

El rang 10.213.2.100-200 no coincideix amb cap adreça fixa del [pla d'adreçament](01-arquitectura.md#5-adreçament-ip), de manera que no es pot repartir una adreça que ja usi un servei.

## 3. Instal·lació i configuració
S'arrenca amb la infraestructura (`docker compose up -d --build`).

| Fitxer | Contingut |
|---|---|
| `services/dhcp/init.sh` | Escriu la configuració a `/etc/dnsmasq.d/p00-dhcp.conf` i la valida amb `dnsmasq --test`. Si falla, el contenidor no arrenca |
| `docker-compose.yml` | Servei `dhcp`: adreça fixa, capacitats `NET_ADMIN` i `NET_RAW`, `command` amb `--conf-file` i `healthcheck` |

Opcions principals de la configuració:

| Opció | Efecte |
|---|---|
| `dhcp-range=10.213.2.100,10.213.2.200,255.255.255.0,12h` | Rang i temps de cessió |
| `dhcp-authoritative` | Respon de seguida a les peticions de la xarxa |
| `dhcp-option=option:router,10.213.2.254` | Gateway que reben els clients |
| `dhcp-option=option:dns-server,10.213.2.53` | Servidor DNS que reben els clients |
| `listen-address=10.213.2.67` i `bind-interfaces` | Només escolta a la intranet |
| `log-dhcp` | Les peticions queden a `docker logs DHCP-N06` |

Igual que al DNS, `dnsmasq` no llegeix `/etc/dnsmasq.d` si no l'arrenca el servei del sistema, i per això el `command` li passa el fitxer amb `--conf-file`.

## 4. Seguretat i limitacions
| Aspecte | Detall |
|---|---|
| Abast | El servidor només escolta a l'adreça de la intranet; el pont Docker de la intranet no està unit a la xarxa del laboratori, de manera que no reparteix adreces a Isard |
| Clients de `itb 6` | **No poden obtenir adreça d'aquest DHCP.** Les peticions DHCP són difusions (*broadcast*) i no travessen l'enrutament pel qual els clients arriben a la intranet. Tenen l'adreça fixa ([document 04](04-clients-isard.md)) |
| Xarxa d'Isard | No s'activa DHCP a `itb 6` perquè és una xarxa compartida del laboratori |
| Cessions | No es guarden en un volum: si es recrea el contenidor, es perden i els equips les tornen a demanar |

## 5. Comprovacions
Els clients d'`itb 6` no poden demanar adreça (apartat 4); per això les proves es fan amb un contenidor temporal connectat a la intranet (xarxa `p00-n06_intranet`), que fa de client DHCP. Resultats del 22/11/2026.

### 5.1 Oferta amb `nmap` (requisit de l'enunciat)
Es llança el *script* `broadcast-dhcp-discover` d'`nmap`, que envia una petició DHCP per difusió i mostra l'oferta rebuda:

```bash
docker run --rm --network p00-n06_intranet --cap-add NET_RAW --cap-add NET_ADMIN \
  instrumentisto/nmap -e eth0 --script broadcast-dhcp-discover
```

Resultat obtingut:

```
| broadcast-dhcp-discover:
|   Response 1 of 1:
|     Interface: eth0
|     IP Offered: 10.213.2.117
|     DHCP Message Type: DHCPOFFER
|     Server Identifier: 10.213.2.67
|     IP Address Lease Time: 12h00m00s
|     Renewal Time Value: 6h00m00s
|     Rebinding Time Value: 10h30m00s
|     Subnet Mask: 255.255.255.0
|     Broadcast Address: 10.213.2.255
|     Domain Name: asix.local
|     Domain Name Server: 10.213.2.53
|_    Router: 10.213.2.254
```

L'oferta ve de `10.213.2.67`, és dins del rang 10.213.2.100-200 i porta el router, el DNS i el domini esperats. Només hi ha una resposta (`Response 1 of 1`), de manera que a la intranet no hi ha cap altre servidor DHCP. `nmap` avisa que no ha escanejat cap equip (`No targets were specified`): és normal, perquè aquest *script* actua abans de l'escaneig i no necessita cap destinació.

### 5.2 Cicle complet amb `udhcpc`
Es comprova a més que el client arriba a acceptar l'adreça (DISCOVER, OFFER, REQUEST i ACK):

```bash
docker run --rm --network p00-n06_intranet --cap-add NET_ADMIN busybox sh -c '
printf "#!/bin/sh\nenv | grep -E \"^(ip|subnet|router|dns|domain|lease|serverid)=\"\n" > /tmp/s; chmod +x /tmp/s
udhcpc -i eth0 -n -q -f -s /tmp/s'
```

| # | Comprovació | Esperat | Obtingut |
|---|---|---|---|
| 1 | Adreça rebuda | Dins del rang 10.213.2.100-200 | `ip=10.213.2.115` (en aquesta execució) |
| 2 | Màscara | 255.255.255.0 | `subnet=255.255.255.0` |
| 3 | Router | 10.213.2.254 | `router=10.213.2.254` |
| 4 | DNS | 10.213.2.53 | `dns=10.213.2.53` |
| 5 | Domini | `asix.local` | `domain=asix.local` |
| 6 | Servidor i cessió | 10.213.2.67, 12 hores | `serverid=10.213.2.67` i `lease=43200` |
| 7 | Registre del servidor | Cicle complet | `DHCPDISCOVER`, `DHCPOFFER`, `DHCPREQUEST` i `DHCPACK` per a `10.213.2.115` (`docker logs DHCP-N06`) |

## 6. Resolució de problemes
| Símptoma | Causa | Solució |
|---|---|---|
| El client temporal no rep adreça | El servei no ha arrencat | `docker compose ps dhcp` i `docker logs DHCP-N06` |
| El servidor no mostra cap petició | El client no és a la xarxa de la intranet | Comprovar que el contenidor usa la xarxa `p00-n06_intranet` |
| Un client de `itb 6` no obté adreça | Les difusions no travessen l'enrutament | És una limitació coneguda: usar adreça fixa |
| El contenidor no arrenca | Error a la configuració | `docker logs DHCP-N06` mostra l'error de `dnsmasq --test` |

## 7. Historial de versions
| Versió | Data | Canvis |
|---|---|---|
| 1.0 | 22/11/2026 | Primera versió: dnsmasq com a DHCP, opcions i proves |
