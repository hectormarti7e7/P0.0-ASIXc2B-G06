# Clients a Isard (xarxa itb 6)

| | |
|---|---|
| **Projecte** | P0.0 · Desplegament d'infraestructura |
| **Mòdul** | 0379 · Projecte intermodular (ASIX) |
| **Equip** | G06 (ASIXc2B) · identificador N06 |
| **Autor** | Josep Pérez |
| **Versió** | 1.0 · 17/11/2026 · Sprint 2 |

## Índex
1. [Objectiu i abast](#1-objectiu-i-abast)
2. [Visió general](#2-visió-general)
3. [Connexió de la intranet amb itb 6](#3-connexió-de-la-intranet-amb-itb-6)
4. [Client Linux (PC-L-N06)](#4-client-linux-pc-l-n06)
5. [Proves](#5-proves)
6. [Client Windows (PC-W-N06)](#6-client-windows-pc-w-n06)
7. [Resolució de problemes](#7-resolució-de-problemes)
8. [Historial de versions](#8-historial-de-versions)

## 1. Objectiu i abast
L'enunciat demana dos PC, un Windows i un Linux. En aquest projecte no són contenidors: són **màquines virtuals independents al laboratori d'Isard** que arriben a la infraestructura Docker per la xarxa `itb 6`. Aquest document explica com es connecten a la intranet, com es configura cada client i com es comprova que funcionen.

## 2. Visió general
| Equip | Sistema | Nom | Adreça | Xarxa |
|---|---|---|---|---|
| Client Linux | Ubuntu 24 | `PC-L-N06` | 10.213.2.50/24 | Intranet, per itb 6 |
| Client Windows | Windows | `PC-W-N06` | 10.213.2.60/24 | Intranet, per itb 6 |
| Equip dels serveis | Ubuntu 24 (Docker) | | 192.168.50.22/24 a `enp3s0` | itb 6 |

L'adreça 192.168.50.22 és la que té la targeta d'`itb 6` de l'equip dels serveis fora de la intranet; els clients no l'usen.

Cada màquina virtual té tres targetes de xarxa: *Default* d'Isard (Internet), la VPN d'Isard i `itb 6`. Només `itb 6` forma part de la infraestructura del projecte.

| Element | Estat |
|---|---|
| Client Linux: nom, adreça i MTU configurats; connexió amb el router i la BBDD | Fet (17/11/2026) |
| Client Linux: usuari `bchecker` i eines de prova | Pendent |
| Client Linux: sortida a Internet pel router | Pendent |
| Client Windows | Pendent |

## 3. Connexió de la intranet amb itb 6
La xarxa `intranet` de Docker és de tipus `ipvlan` en mode L2 i fa servir com a interfície pare la targeta de l'equip connectada a `itb 6`. Així els clients (a `itb 6`) i els contenidors (a la intranet) són a la mateixa xarxa 10.213.2.0/24 i el router (10.213.2.254) és el *gateway* dels dos.

```yaml
networks:
  intranet:
    driver: ipvlan
    driver_opts:
      parent: ${INTRANET_PARENT:-enp3s0}
      ipvlan_mode: l2
    ipam:
      config: [{ subnet: 10.213.2.0/24, gateway: 10.213.2.1 }]
```

La targeta es tria amb la variable `INTRANET_PARENT` del `.env` (`ip -br addr` mostra les targetes de l'equip).

### 3.1 Per què `ipvlan` i no un pont
La primera prova va ser unir la targeta d'`itb 6` al pont de la intranet. Els clients enviaven la petició ARP, el router (contenidor) contestava per la targeta de l'equip, però la resposta no arribava al client. Amb `tcpdump` es va veure la resposta sortint amb la MAC del contenidor, diferent de la MAC de la targeta virtual. El més probable és que la xarxa virtual d'Isard descarti els paquets amb una MAC d'origen que no és la de la targeta.

Amb `ipvlan` tots els contenidors surten amb la MAC de la targeta de l'equip i els clients reben les respostes. Aquesta explicació és una deducció a partir de les proves, no s'ha comprovat a la configuració d'Isard.

### 3.2 Limitacions
- L'equip dels serveis no pot arribar directament a les adreces 10.213.2.x; per entrar als contenidors s'usa `docker exec`. Els clients sí que hi arriben.
- La targeta indicada a `INTRANET_PARENT` no pot ser alhora un port d'un pont (`ip link set <targeta> nomaster` per deixar-la lliure).
- Per canviar el tipus de la xarxa `intranet` cal aturar tots els contenidors que hi són connectats (`docker compose down --remove-orphans`).

## 4. Client Linux (PC-L-N06)
### 4.1 Màquina virtual
Ubuntu 24, amb tres targetes de xarxa: *Default*, la VPN d'Isard i `itb 6`. A la màquina, `itb 6` és `enp3s0`.

### 4.2 Configuració de la xarxa
La targeta d'`itb 6` té una MTU de 8946, i els ponts de Docker usen 1500. Si el client enviés paquets grans, es perdrien, per això es fixa la MTU a 1500. L'adreça és fixa, sense *gateway* (Internet continua sortint per la xarxa *Default*):

```bash
sudo hostnamectl set-hostname PC-L-N06
CON=$(nmcli -g GENERAL.CONNECTION device show enp3s0)
sudo nmcli con mod "$CON" ipv4.method manual ipv4.addresses 10.213.2.50/24 802-3-ethernet.mtu 1500
sudo nmcli con up "$CON"
ip -4 addr show enp3s0
```
Resultat esperat: `enp3s0` amb `10.213.2.50/24` i `mtu 1500`.

### 4.3 Usuari bchecker
L'enunciat demana l'usuari `bchecker` a tots els sistemes:
```bash
sudo useradd -m -s /bin/bash -G sudo bchecker
echo 'bchecker:bchecker121' | sudo chpasswd
id bchecker
```

### 4.4 Eines de prova
```bash
sudo apt-get update
sudo apt-get install -y nmap mysql-client ftp traceroute
for c in nmap mysql ftp traceroute; do printf "%s: " $c; which $c || echo NO; done
```
Es descarreguen per la xarxa *Default*.

## 5. Proves
### 5.1 Connexió amb la intranet
```bash
ip neigh flush dev enp3s0
ping -c 3 10.213.2.254
ping -c 3 10.213.2.10
ip neigh show dev enp3s0
```
Resultat esperat: els dos `ping` responen sense pèrdues i la taula ARP mostra les dues adreces amb una MAC i l'estat `REACHABLE`.

### 5.2 Sortida a Internet pel router
Per comprovar que el trànsit surt pel router (`R-N06`), es prova de forma temporal amb una ruta que només dura fins al reinici:
```bash
sudo ip route replace default via 10.213.2.254 dev enp3s0 metric 50
traceroute -n 1.1.1.1 | head -4
ping -c 2 1.1.1.1
sudo ip route del default via 10.213.2.254 dev enp3s0 metric 50
```
Resultat esperat: el primer salt és el router (`10.213.2.254`) i el segon el *gateway* de la xarxa NAT (`10.213.3.1`).

### 5.3 Accés a la base de dades
Un cop instal·lades les eines, des del client:
```bash
mysql -h 10.213.2.10 -ubchecker -pbchecker121 -e "SHOW DATABASES;"
```
Resultat esperat: la llista de bases de dades amb `equipaments`.

## 6. Client Windows (PC-W-N06)
Pendent. Procediment previst, igual que al client Linux:
1. Màquina virtual Windows a Isard amb les xarxes *Default* i `itb 6`.
2. Adreça fixa 10.213.2.60/24 a la targeta d'`itb 6`, amb el router (10.213.2.254) com a *gateway* quan es vulgui provar la sortida pel router.
3. MTU a 1500 (a la consola d'administrador: `netsh interface ipv4 set subinterface "<nom de la targeta>" mtu=1500 store=persistent`).
4. Usuari `bchecker` (`net user bchecker bchecker121 /add`) amb els permisos necessaris per entrar a l'equip.
5. Les mateixes proves de l'apartat 5, amb `ping` i `Test-NetConnection`.

## 7. Resolució de problemes
| Símptoma | Causa probable | Solució |
|---|---|---|
| `Destination Host Unreachable` i l'ARP queda en `FAILED` | La xarxa `intranet` encara no és `ipvlan` o els contenidors no estan aixecats | `docker compose ps` i `docker network inspect p00-n06_intranet` a l'equip dels serveis (ha de dir `ipvlan`) |
| La petició ARP arriba a l'equip dels serveis però el client no rep la resposta | Un pont fa que els contenidors surtin amb la seva MAC i la xarxa virtual la descarta | Usar `ipvlan` (apartat 3) |
| Les connexions petites van bé però les grans es queden penjades | La MTU del client és 8946 i la de la intranet 1500 | Posar la MTU del client a 1500 (apartat 4.2) |
| Des de l'equip dels serveis no s'arriba a 10.213.2.x | És una limitació de `ipvlan` | Usar `docker exec <contenidor> ...` |
| Error en crear la xarxa `intranet` | La targeta de `INTRANET_PARENT` no existeix o és port d'un pont | `ip -br addr`, corregir el `.env` i `sudo ip link set <targeta> nomaster` |
| `Pool overlaps with other one on this address space` en canviar la xarxa | Hi ha contenidors antics a la xarxa `intranet` | `docker compose down --remove-orphans` i tornar a aixecar |

## 8. Historial de versions
| Versió | Data | Canvis |
|---|---|---|
| 1.0 | 17/11/2026 | Primera versió: connexió per itb 6 amb `ipvlan`, configuració del client Linux i proves |
