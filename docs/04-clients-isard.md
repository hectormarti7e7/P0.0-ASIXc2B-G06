# Clients a Isard (xarxa itb 6)

| | |
|---|---|
| **Projecte** | P0.0 · Desplegament d'infraestructura |
| **Mòdul** | 0379 · Projecte intermodular (ASIX) |
| **Equip** | G06 (ASIXc2B) · identificador N06 |
| **Autor** | Josep Pérez |
| **Versió** | 1.1 · 18/11/2026 · Sprint 2 |

## Índex
1. [Objectiu i abast](#1-objectiu-i-abast)
2. [Visió general](#2-visió-general)
3. [Connexió dels clients amb la intranet](#3-connexió-dels-clients-amb-la-intranet)
4. [Client Linux (PC-L-N06)](#4-client-linux-pc-l-n06)
5. [Proves](#5-proves)
6. [Client Windows (PC-W-N06)](#6-client-windows-pc-w-n06)
7. [Resolució de problemes](#7-resolució-de-problemes)
8. [Historial de versions](#8-historial-de-versions)

## 1. Objectiu i abast
L'enunciat demana dos PC, un Windows i un Linux. En aquest projecte no són contenidors: són **màquines virtuals independents al laboratori d'Isard** que arriben als serveis Docker per la xarxa `itb 6`. Aquest document explica com es connecten, com es configura cada client i com es comprova que funcionen.

## 2. Visió general
| Equip | Sistema | Nom | Adreça a itb 6 | Estat |
|---|---|---|---|---|
| Equip dels serveis | Ubuntu 24 (Docker) | `ubuntu-24` | 192.168.50.22/24 (`enp3s0`) | Fet |
| Client Linux | Ubuntu 24 | `PC-L-N06` | 192.168.50.50/24 | Arriba al router (18/11/2026); proves amb la BBDD pendents |
| Client Windows | Windows | `PC-W-N06` | 192.168.50.60/24 | Pendent |

Cada màquina virtual té tres targetes de xarxa: *Default* d'Isard (Internet), la VPN d'Isard i `itb 6`. Només `itb 6` forma part de la infraestructura del projecte. Abans de fixar les adreces .50 i .60 es va comprovar amb `ping` que cap altre equip d'`itb 6` no les feia servir.

## 3. Connexió dels clients amb la intranet
Els clients són a `itb 6` (192.168.50.0/24) i els contenidors a la intranet (10.213.2.0/24). L'equip dels serveis, que és a les dues xarxes, fa de *gateway*:

```
Client (192.168.50.50)  --itb 6-->  Equip dels serveis (enp3s0 .22 · br-intranet 10.213.2.1)  -->  contenidors
         ^                                                                                         |
         '------------------------------ resposta pel router (R-N06) ----------------------------'
```

| Peça | On | Què fa |
|---|---|---|
| Ruta `10.213.2.0/24 via 192.168.50.22` | Cada client | Envia el trànsit de la intranet a l'equip dels serveis |
| `scripts/xarxa-clients.sh` | Equip dels serveis | Activa el reenviament i obre `DOCKER-USER` entre `enp3s0` i `br-intranet` |
| `192.168.50.0/24 via 10.213.2.1` | Router (`services/router/init.sh`) | Les respostes tornen cap a l'equip dels serveis |
| `gateway_mode_ipv4: nat-unprotected` | Xarxa `intranet` (`docker-compose.yml`) | Permet l'accés directe a les IP dels contenidors |

La xarxa `intranet` és un pont normal amb nom fix (`br-intranet`). Després de cada `docker compose up` cal executar el script a l'equip dels serveis:

```bash
sudo ./scripts/xarxa-clients.sh
```

El script és idempotent. Les regles no sobreviuen a un reinici de l'equip ni a recrear la xarxa.

### 3.1 Per què no s'ha connectat la targeta directament a la intranet
Es van provar dues opcions abans:

- **Pont (*bridge*) amb la targeta d'`itb 6`.** Els clients enviaven l'ARP i el contenidor responia, però la resposta no arribava. La captura amb `tcpdump` mostrava la resposta sortint amb la MAC del contenidor, diferent de la de la targeta virtual. Probablement la xarxa virtual d'Isard descarta els paquets amb una MAC d'origen que no és la de la targeta (és una deducció a partir de les proves).
- **`ipvlan` L2.** Els clients arribaven als contenidors, però el trànsit que havia de passar pel router no hi arribava: `ipvlan` lliura els paquets segons la IP de destí, i un paquet cap a Internet o cap a la DMZ no té cap contenidor com a destí, de manera que sortia per la targeta `enp3s0` (es va comprovar amb `tcpdump`). Això hauria impedit que la web de la DMZ arribés a la BBDD.

### 3.2 Docker 28 i l'enrutament directe
Des de Docker 28, Docker afegeix a la taula `raw` regles `PREROUTING ... -j DROP` que descarten el trànsit cap a les IP dels contenidors si no arriba pel seu pont. Aquestes regles s'apliquen abans de `DOCKER-USER`, així que no es poden contrarestar des d'allà. Per això la xarxa `intranet` usa el mode `nat-unprotected`. Es comprova que les regles han desaparegut:

```bash
sudo iptables -t raw -S
```

Només han de quedar les de les xarxes `dmz` i `nat`, no les de la intranet.

### 3.3 Limitacions
- El DHCP de la intranet no pot repartir adreces als clients, perquè la difusió no travessa l'enrutament. Els clients tenen l'adreça fixa.
- Les adreces 192.168.50.x són les del laboratori d'Isard. En un altre entorn cal canviar-les al script, al router i als clients.

## 4. Client Linux (PC-L-N06)
### 4.1 Màquina virtual
Ubuntu 24, amb tres targetes de xarxa: *Default*, la VPN d'Isard i `itb 6`. A la màquina, `itb 6` és `enp3s0`.

### 4.2 Configuració de la xarxa
La targeta d'`itb 6` té una MTU de 8946, i el pont de Docker usa 1500. Es fixa a 1500 al client perquè els paquets grans no es perdin. L'adreça és fixa i s'hi afegeix la ruta cap a la intranet:

```bash
sudo hostnamectl set-hostname PC-L-N06
CON=$(nmcli -g GENERAL.CONNECTION device show enp3s0)
sudo nmcli con mod "$CON" ipv4.method manual ipv4.addresses 192.168.50.50/24 \
  ipv4.routes "10.213.2.0/24 192.168.50.22" 802-3-ethernet.mtu 1500
sudo nmcli con up "$CON"
ip -4 addr show enp3s0
ip route
```
Resultat esperat: `enp3s0` amb `192.168.50.50/24` i `mtu 1500`, i la ruta `10.213.2.0/24 via 192.168.50.22 dev enp3s0`. Internet continua sortint per la xarxa *Default*.

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
Des del client:
```bash
ping -c 3 10.213.2.254
ping -c 3 10.213.2.10
```
Resultat esperat: cap paquet perdut. El `ttl=63` del router indica que el paquet ha passat per l'equip dels serveis. El 18/11/2026 el `ping` al router va respondre amb 0,3 ms de mitjana.

### 5.2 Sortida a Internet pel router
El client surt a Internet per la xarxa *Default*, no pel router. La sortida a Internet de la intranet pel router es comprova des d'un contenidor, a l'equip dels serveis:
```bash
docker exec B-N06 ip route show default
docker exec B-N06 ping -c 3 1.1.1.1
```
Resultat esperat: `default via 10.213.2.254` i cap paquet perdut.

### 5.3 Accés a la base de dades
Un cop instal·lades les eines, des del client:
```bash
mysql -h 10.213.2.10 -ubchecker -pbchecker121 -e "SHOW DATABASES;"
```
Resultat esperat: la llista de bases de dades amb `equipaments`.

## 6. Client Windows (PC-W-N06)
Pendent. Procediment previst:
1. Màquina virtual Windows a Isard amb les xarxes *Default* i `itb 6`.
2. Adreça fixa 192.168.50.60/24 a la targeta d'`itb 6`, sense *gateway*.
3. MTU a 1500 i ruta cap a la intranet, des d'una consola d'administrador (el nom de la targeta es veu amb `netsh interface ipv4 show interfaces`):
```
netsh interface ipv4 set subinterface "<nom de la targeta>" mtu=1500 store=persistent
route -p add 10.213.2.0 mask 255.255.255.0 192.168.50.22
```
4. Usuari `bchecker` (`net user bchecker bchecker121 /add`) amb els permisos necessaris per entrar a l'equip.
5. Les mateixes proves de l'apartat 5, amb `ping` i `Test-NetConnection -ComputerName 10.213.2.10 -Port 3306`.

## 7. Resolució de problemes
| Símptoma | Causa probable | Solució |
|---|---|---|
| El client no arriba a 10.213.2.x i els comptadors de `iptables -vnL DOCKER-USER` són 0 | Les regles `raw` de Docker 28 descarten el trànsit | `sudo iptables -t raw -S`: no ha de tenir regles `DROP` de la intranet. Comprovar `gateway_mode_ipv4: nat-unprotected` al compose i recrear la xarxa (`docker compose down` i `up`) |
| Els comptadors de `DOCKER-USER` pugen però no hi ha resposta | El router no té la ruta de tornada | `docker exec R-N06 ip route`: ha de tenir `192.168.50.0/24 via 10.213.2.1` |
| Funcionava i ha deixat de funcionar després d'un reinici o d'un `docker compose up` | S'han perdut les regles de l'equip dels serveis | `sudo ./scripts/xarxa-clients.sh` |
| El client no arriba ni a `192.168.50.22` | Cable o adreça del client incorrectes | `ip -4 addr show enp3s0` i `ip neigh show dev enp3s0` |
| Les connexions petites van bé però les grans es queden penjades | La MTU del client és 8946 | Posar la MTU del client a 1500 (apartat 4.2) |
| El script diu que no existeix el pont `br-intranet` | La infraestructura no està aixecada | `docker compose up -d` i tornar a executar el script |
| Error en crear la xarxa `intranet` perquè ja existeix amb un altre tipus | Queda una xarxa antiga (`ipvlan`) d'una versió anterior | `docker compose down --remove-orphans` i tornar a aixecar |

## 8. Historial de versions
| Versió | Data | Canvis |
|---|---|---|
| 1.0 | 17/11/2026 | Primera versió: connexió per itb 6 amb `ipvlan` i configuració del client Linux |
| 1.1 | 18/11/2026 | Els clients arriben a la intranet per enrutament a través de l'equip dels serveis, amb adreces d'itb 6, perquè `ipvlan` impedia el pas pel router |
