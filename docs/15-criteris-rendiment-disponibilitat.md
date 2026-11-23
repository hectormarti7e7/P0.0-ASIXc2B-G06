# Criteris de rendiment i disponibilitat, i pla de proves

| | |
|---|---|
| **Projecte** | P0.0 · Desplegament d'infraestructura |
| **Mòdul** | 0379 · Projecte intermodular (ASIX) |
| **Equip** | G06 (ASIXc2B) · identificador N06 |
| **Autor** | Josep Pérez |
| **Versió** | 2.0 · 23/11/2026 · Sprint 2 |

## Índex
1. [Objectiu i abast](#1-objectiu-i-abast)
2. [Definicions](#2-definicions)
3. [Criteris](#3-criteris)
4. [Com es mesura](#4-com-es-mesura)
5. [Estat d'implementació](#5-estat-dimplementació)
6. [Registre de mesures](#6-registre-de-mesures)
7. [Pla de proves](#7-pla-de-proves)
8. [Historial de versions](#8-historial-de-versions)

## 1. Objectiu i abast
Aquest document defineix els criteris de rendiment i de disponibilitat de la infraestructura, amb objectius mesurables i amb la manera de comprovar-los, i recull el pla de proves (apartat 7) amb el resultat de cada prova. Els valors són els objectius de l'equip. Es revisen amb les mesures reals, que es fan quan els serveis estan desplegats (sprints 2 i 3), i els resultats es recullen a l'apartat 6.

## 2. Definicions
| Terme | Significat |
|---|---|
| Disponibilitat | Percentatge del temps que un servei respon correctament durant la finestra de mesura |
| Temps de recuperació | Temps que triga un servei a tornar a funcionar després d'una aturada |
| Latència | Temps que triga a respondre una petició o un `ping` |
| Finestra de mesura | Període en què es mesura, d'1 hora com a mínim i sense aturades provocades a propòsit |

## 3. Criteris
| ID | Criteri | Objectiu | Servei afectat |
|---|---|---|---|
| D1 | Disponibilitat dels serveis | 99 % o més a la finestra de mesura, amb una sonda cada 60 s | Web, BBDD, DNS, DHCP, FTP i SSH |
| D2 | Temps de recuperació després d'aturar un contenidor amb `docker kill` | 60 s o menys | Tots els serveis |
| D3 | Arrencada del router fins a l'estat `healthy` | 30 s o menys | Router |
| D4 | Arrencada de la BBDD fins a l'estat `healthy`, en la primera arrencada | 120 s o menys | BBDD |
| P1 | Latència entre equips d'una mateixa xarxa | 5 ms o menys de mitjana i 0 % de paquets perduts | Xarxes |
| P2 | Sortida a Internet des de la intranet pel router | Ruta per defecte pel router (10.213.2.254) i 0 % de paquets perduts | Router i clients |
| P3 | Resposta de la web amb 10 usuaris concurrents | 0 peticions fallides i temps mitjà de 500 ms o menys | Web |
| P4 | Consulta de recompte a la taula carregada | 1 s o menys | BBDD |
| P5 | Càrrega del CSV d'equipaments | 60 s o menys i totes les files carregades | BBDD |
| R1 | Memòria per contenidor | 512 MiB o menys (la BBDD, 1 GiB o menys) | Tots |
| R2 | CPU d'un contenidor en repòs | 5 % o menys | Tots |

## 4. Com es mesura
### Estat i arrencada (D3, D4)
```bash
time docker compose up -d --wait
docker compose ps
docker inspect -f '{{.State.Health.Status}}' R-N06
```

### Recuperació (D2)
Es desa l'hora i s'atura el contenidor; després es comparen les hores dels esdeveniments `kill` i `start`, o el moment en què la sonda d'Uptime Kuma torna a estar en verd:
```bash
docker kill R-N06
docker events --since 5m --until 0s --filter container=R-N06 --filter event=kill --filter event=start
```

### Disponibilitat (D1)
Sondes d'Uptime Kuma per IP, una per servei i amb interval de 60 s. La disponibilitat és el percentatge que mostra el monitor a la finestra de mesura.

### Xarxa (P1, P2)
P1 es mesura des del client Linux (màquina virtual d'Isard) i P2 des d'un contenidor de la intranet, perquè el client surt a Internet per l'equip dels serveis i no pel router ([document dels clients](04-clients-isard.md), apartat 5).
```bash
# Al client Linux (P1)
ping -c 20 10.213.2.254

# A l'equip dels serveis (P2)
docker exec B-N06 ping -c 20 1.1.1.1
docker exec B-N06 ip route show default
```
Ha de mostrar `default via 10.213.2.254` i cap paquet perdut.

### Web i BBDD (P3, P4, P5)
```bash
ab -n 200 -c 10 http://10.213.1.10/
time mysql -h 10.213.2.10 -ubchecker -pbchecker121 equipaments -e "SELECT COUNT(*) FROM <taula>;"
```
`ab` forma part d'`apache2-utils` i s'instal·la al client de proves. El temps de càrrega del CSV (P5) és el que triga a executar-se l'script de càrrega.

### Recursos (R1, R2)
```bash
docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}'
```

## 5. Estat d'implementació
| Element | Estat |
|---|---|
| Política de reinici `restart: unless-stopped` a tots els serveis (`docker-compose.yml`) | Fet |
| `healthcheck` del router (regla `MASQUERADE`) i espera de la BBDD fins que el router és `healthy` | Fet |
| `healthcheck` de la BBDD (`mysqladmin ping` amb l'usuari `bchecker`) | Fet |
| Script de càrrega del CSV (`load_csv.py`), mesurat (P5) | Fet |
| Sondes d'Uptime Kuma per servei | Fet ([document 26](26-monitoritzacio.md)) |
| Prova de caiguda i recuperació de la BBDD (`docker stop` i `docker start`) | Fet (23/11/2026, [document 26](26-monitoritzacio.md)) |
| Proves de càrrega amb `ab` i prova de recuperació amb `docker kill` (D2) | Pendent (sprint 3) |

## 6. Registre de mesures
Es completa amb cada mesura feta. Fins ara només s'han mesurat D4 i P5; la resta de criteris estan pendents de mesurar.

| Data | Criteri | Valor mesurat | Objectiu | Compleix | Observacions |
|---|---|---|---|---|---|
| 16/11/2026 | D4 | 6,8 s | 120 s o menys | Sí | `time docker compose up -d --wait db` amb volum nou, imatge ja construïda i router en marxa |
| 19/11/2026 | P5 | 1,0 s (2.709 files) | 60 s o menys i totes les files | Sí | `time docker exec B-N06 python3 /opt/load_csv.py`; una sola mesura ([càrrega del CSV](03-bbdd-mysql.md#5-càrrega-del-csv)) |

## 7. Pla de proves
La columna «Resultat» només s'omple amb el que s'ha executat de veritat; la resta queda com a **Pendent**. Els resultats detallats són als documents de cada servei.

Convencions: `W-N06` web, `F-N06` FTP, `S-N06` SSH, `B-N06` base de dades, `DNS-N06`, `DHCP-N06`, `MON-N06` monitor, `R-N06` router. IP: W 10.213.1.10, F 10.213.1.11, S 10.213.1.12, B 10.213.2.10, MON 10.213.2.20, DNS 10.213.2.53, DHCP 10.213.2.67, router 10.213.2.254.

### 7.1 Proves funcionals
| ID | Prova | Ordre o acció | Resultat esperat | Resultat |
|---|---|---|---|---|
| F1 | Contenidors en marxa | `docker compose ps` | Tots els serveis en estat `running` o `healthy` | **Pendent** (es cobreix amb A1) |
| F2 | Dades carregades | `SELECT COUNT(*)` a la taula carregada | 2.709 files | Verificat (doc 03) |
| F3 | Web per HTTPS amb credencials | `curl -k -u usuari:contrasenya https://<host>/` | `200` | Verificat (doc 06) |
| F4 | Redirecció HTTP a HTTPS | `curl -I http://<host>/` | `301` | Verificat (doc 06) |
| F5 | Llistat FTP | Connexió a `F-N06` pel port 21 | Llistat del directori | Verificat (doc 24) |
| F6 | Resolució DNS del router | `dig @10.213.2.53 r-n06.asix.local` | `10.213.2.254` | Verificat (doc 08) |
| F7 | Concessió DHCP | `nmap --script broadcast-dhcp-discover` i `udhcpc` | Cicle DISCOVER, OFFER, REQUEST, ACK | Verificat (doc 25) |
| F8 | Client Linux arriba als serveis | Ping i SSH des de `PC-L-N06` | Respostes correctes | Verificat (docs 04 i 07) |
| F9 | Client Windows arriba als serveis | Pings a 192.168.50.22, 10.213.2.1, 10.213.2.254 i 10.213.2.10 | Respostes correctes | **Pendent** (Hèctor Martí) |
| F10 | Usuari `bchecker` als contenidors | `docker exec <contenidor> id bchecker` als vuit contenidors | L'usuari existeix i és del grup `sudo` | Verificat el 23/11/2026: `uid=1000` a set contenidors i `uid=1001` a `MON-N06`, tots amb el grup `sudo` |

### 7.2 Proves de seguretat
| ID | Prova | Ordre o acció | Resultat esperat | Resultat |
|---|---|---|---|---|
| S1 | SSH amb clau | `ssh -p 2222 -i <clau> bchecker@<host>` | Accés concedit | Verificat (doc 07) |
| S2 | SSH sense clau | Intent sense clau | Denegat | Verificat (doc 07) |
| S3 | SSH com a `root` | `ssh -p 2222 root@<host>` | Denegat | Verificat (doc 07) |
| S4 | Configuració efectiva de `sshd` | `sshd -T` | `passwordauthentication no` | Verificat (doc 07) |
| S5 | Web sense credencials | `curl -k https://<host>/` | `401` | Verificat (doc 06) |
| S6 | Web amb contrasenya incorrecta | `curl -k -u usuari:malament https://<host>/` | `401` | Verificat (doc 06) |
| S7 | Ruta lliure | `curl -k https://<host>/health` | `200` sense credencials | Verificat (doc 06) |
| S8 | Aïllament DMZ a BD | Des de la DMZ, connexió al port 22 de `B-N06` | Bloquejada pel router | Verificat el 22/11/2026 (doc 06, apartat 5.1: `echo > /dev/tcp/10.213.2.10/22`, la connexió no s'estableix) |
| S9 | Accés DMZ a MySQL | Des de la DMZ, port 3306 de `B-N06` | Permès (regla del router) | Verificat el 22/11/2026 (doc 06, apartat 5.1: la web llegeix 2709 files de la BBDD) |
| S10 | FTP: accessos no permesos | `curl -T` a l'arrel, contrasenya incorrecta i `--user root` | Denegats | Verificat (doc 24: codis 25, 67 i 67) |
| S11 | FTP: sortir de la carpeta | `curl ftp://<host>/../etc/passwd` | No es pot veure | Verificat (doc 24: codi 9) |
| S12 | DNS: nom inexistent del domini intern | `dig nonexistent.asix.local` | `NXDOMAIN`, sense reenviar a Internet | Verificat (doc 08) |

### 7.3 Proves de contingència
| ID | Prova | Procediment | Resultat esperat | Resultat |
|---|---|---|---|---|
| C1 | Caiguda de la BD | `docker stop B-N06` i observar el tauler | La sonda MySQL passa a caiguda | Verificat el 23/11/2026 (doc 26) |
| C2 | Recuperació de la BD | `docker start B-N06` | La sonda torna a estar activa | Verificat el 23/11/2026 (doc 26) |
| C3 | Recreació d'un servei | `docker compose up -d --force-recreate <servei>` | El servei torna a estar actiu | Verificat amb `dns` |
| C4 | Còpia i restauració de la BD | `mysqldump` i restauració | Les files tornen a ser 2.709 | **Pendent**: la còpia es descriu al doc 03 però no s'ha provat la restauració |
| C5 | Reinici de l'host | Reiniciar i tornar a executar `xarxa-clients.sh` | Els clients tornen a tenir accés | **Pendent** |

### 7.4 Proves de monitorització
| ID | Prova | Resultat esperat | Resultat |
|---|---|---|---|
| M1 | Sonda web | Activa | Verificat (doc 26) |
| M2 | Sonda FTP | Activa | Verificat (doc 26) |
| M3 | Sonda SSH | Activa | Verificat (doc 26) |
| M4 | Sonda MySQL | Activa | Verificat (doc 26) |
| M5 | Sonda DNS | Activa | Verificat (doc 26) |
| M6 | Estat des de l'script | `estat_sondes.py` mostra les cinc sondes | Verificat (doc 26) |

### 7.5 Proves d'automatització
L'script `scripts/comprova.sh` executa part de les proves anteriors i mostra `PASS` o `FAIL` per a cadascuna. Cobreix F1, F3, F4, F6, S2 i S5, entre d'altres.

| ID | Prova | Resultat |
|---|---|---|
| A1 | Executar `./scripts/comprova.sh` a l'host | **Pendent** d'executar i anotar la sortida |

### 7.6 Com s'anota un resultat
1. Executar la prova i copiar la sortida real.
2. Afegir-la al document del servei corresponent amb la data real i deixar-ne constància a ProofHub.
3. Canviar «Pendent» per «Verificat» només en aquest moment.

## 8. Historial de versions
| Versió | Data | Canvis |
|---|---|---|
| 1.0 | 15/11/2026 | Primera versió: criteris, mètode de mesura i estat d'implementació |
| 1.1 | 16/11/2026 | `healthcheck` de la BBDD i primera mesura (D4) |
| 1.2 | 17/11/2026 | Les mesures de xarxa es fan des del client Linux, que ara és una màquina virtual |
| 1.3 | 18/11/2026 | P2 es mesura des de la BBDD, perquè el client surt a Internet per Isard |
| 1.4 | 19/11/2026 | Primera mesura de P5 (càrrega del CSV) |
| 2.0 | 23/11/2026 | S'hi integra el pla de proves (abans en un document a part) i s'actualitza l'estat de les sondes |
