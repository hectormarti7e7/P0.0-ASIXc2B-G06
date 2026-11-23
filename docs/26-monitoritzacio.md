# Monitorització amb Uptime Kuma (MON-N06)

| | |
|---|---|
| **Projecte** | P0.0 · Desplegament d'infraestructura |
| **Mòdul** | 0379 · Projecte intermodular (ASIX) |
| **Equip** | G06 (ASIXc2B) · identificador N06 |
| **Autors** | Hèctor Martí, Josep Pérez |
| **Versió** | 1.0 · 23/11/2026 · Sprint 2 |

## Índex
1. [Objectiu i abast](#1-objectiu-i-abast)
2. [Característiques](#2-característiques)
3. [Instal·lació i configuració](#3-installació-i-configuració)
4. [Sondes](#4-sondes)
5. [Comprovacions i prova de contingència](#5-comprovacions-i-prova-de-contingència)
6. [Seguretat i limitacions](#6-seguretat-i-limitacions)
7. [Resolució de problemes](#7-resolució-de-problemes)
8. [Historial de versions](#8-historial-de-versions)

## 1. Objectiu i abast
Aquest document descriu el monitor de xarxa `MON-N06`: comprova cada pocs segons que els serveis de la pràctica responen, en guarda l'historial i detecta quan un cau. Inclou la prova de contingència: parar la base de dades i comprovar que el monitor ho detecta i que es recupera en tornar-la a arrencar.

## 2. Característiques
| Element | Valor |
|---|---|
| Contenidor | `MON-N06`, imatge pròpia construïda sobre `louislam/uptime-kuma:1.23.16` |
| Xarxa i adreça | Intranet · 10.213.2.20 (gateway: el router, 10.213.2.254) · port 3001 |
| Interfície web | `http://10.213.2.20:3001` (accessible des dels clients per la mateixa ruta que la base de dades) |
| Administrador | `bchecker` / `bchecker121` (l'usuari que exigeix l'enunciat) |
| Persistència | Volum Docker `monitor-data` (`/app/data`): les sondes i l'historial sobreviuen a un reinici |
| Interval | 20 segons, amb un reintent: una caiguda es detecta en menys d'un minut |

## 3. Instal·lació i configuració
| Fitxer | Contingut |
|---|---|
| `services/monitor/Dockerfile` | Parteix de la imatge oficial d'Uptime Kuma i hi afegeix les eines de xarxa, SSH i l'usuari `bchecker` |
| `services/monitor/monitor-entrypoint.sh` | Fixa el gateway (el router) i el DNS de la pràctica, arrenca SSH i, després, Uptime Kuma |
| `services/monitor/configura_sondes.py` | Crea l'administrador i les sondes. Es pot repetir: només crea el que no existeix |
| `services/monitor/estat_sondes.py` | Mostra l'últim estat de cada sonda (només lectura) |
| `docker-compose.yml` | Servei `monitor`: adreça fixa, volum i `healthcheck` |

La imatge oficial es basa en Debian 10 (*buster*), que ja no té repositoris normals; el `Dockerfile` apunta `apt` a `archive.debian.org` per poder instal·lar les eines.

### 3.1 Desplegament
```bash
docker compose up -d --build monitor      # des de l'equip dels serveis
docker compose ps monitor                 # ha de sortir «healthy»
```

### 3.2 Configuració de les sondes
Les sondes es creen amb un *script* en lloc de fer-ho a mà a la web, de manera que és repetible. S'executa en un contenidor temporal de Python (no instal·la res a l'equip):

```bash
docker run --rm --network host -v "$PWD/services/monitor:/s:ro" python:3.12-slim \
  sh -c 'pip install -q uptime-kuma-api; python /s/configura_sondes.py'
```

La primera vegada crea l'administrador; les següents només afegeixen les sondes que falten.

## 4. Sondes
| Sonda | Tipus | Destinació | Què comprova |
|---|---|---|---|
| Web W-N06 (HTTPS) | HTTP(S) | `https://10.213.1.10/` | Que respon `200` amb autenticació HTTP Basic (accepta el certificat autosignat) |
| FTP F-N06 | Port TCP | 10.213.1.11:21 | Que el port de control FTP accepta connexions |
| SSH S-N06 | Port TCP | 10.213.1.12:2222 | Que el port SSH accepta connexions |
| MySQL B-N06 | MySQL | `10.213.2.10:3306`, base `equipaments` | Que es pot connectar i executar `SELECT COUNT(*) FROM equipaments_educacio` (no només que el port estigui obert) |
| DNS DNS-N06 | DNS | `10.213.2.53`, nom `b-n06.asix.local` | Que resol el nom |

La sonda de MySQL fa una consulta real, que és la sonda adequada per a una base de dades: un servidor pot tenir el port obert i no atendre consultes.

## 5. Comprovacions i prova de contingència
Resultats del 23/11/2026. L'hora del monitor és UTC; la de l'equip dels serveis, hora local (una hora més).

### 5.1 Disponibilitat inicial
Després de crear les sondes, les cinc responen `ACTIU (UP)`: web `200 - OK`, FTP, SSH, MySQL (`Rows: 1`) i DNS (`Records: 10.213.2.10`).

### 5.2 Caiguda i recuperació de la base de dades
Ordres, executades a l'equip dels serveis:
```bash
docker stop B-N06        # caiguda
# ... uns 50 segons ...
docker run --rm --network host -v "$PWD/services/monitor:/s:ro" python:3.12-slim \
  sh -c 'pip install -q uptime-kuma-api; python /s/estat_sondes.py'
docker start B-N06       # recuperació
# ... uns 90 segons ...
```

| Moment | Web | FTP | SSH | MySQL | DNS |
|---|---|---|---|---|---|
| Abans (09:15) | UP (`200 - OK`) | UP | UP | UP (`Rows: 1`) | UP |
| Amb `B-N06` aturat (50 s) | **DOWN** (`status code 503`) | UP | UP | **DOWN** (`connect ETIMEDOUT`) | UP |
| Després de `docker start B-N06` (90 s) | UP (`200 - OK`) | UP | UP | UP (`Rows: 1`) | UP |

Resultats:
- La sonda de MySQL detecta la caiguda en menys d'un minut (`connect ETIMEDOUT`) i es recupera sola quan la base de dades torna a ser `healthy`.
- La web també cau (`503`) mentre la base de dades és aturada, perquè l'aplicació en depèn. Això mostra la **dependència entre serveis** i com el monitor permet localitzar l'origen d'un error: només MySQL i la web són DOWN, i FTP, SSH i DNS no s'han vist afectats.
- Després de la recuperació, la consulta de la sonda (`SELECT COUNT(*) ...`) es torna a executar correctament. La sonda comprova que la base de dades respon, no el nombre de files; aquest es verifica a la [càrrega del CSV](03-bbdd-mysql.md#5-càrrega-del-csv).

## 6. Seguretat i limitacions
- L'administrador d'Uptime Kuma usa les credencials de la pràctica (`bchecker`); en un entorn real en tindria unes pròpies i diferents.
- La interfície web va per HTTP (no HTTPS) i només és accessible des de la intranet i des dels clients d'`itb 6`.
- **No hi ha notificacions** (correu, Telegram…) configurades: les caigudes es veuen a la interfície i amb `estat_sondes.py`. És una millora futura.
- La imatge oficial és antiga (Debian 10) i els paquets que s'hi instal·len vénen de l'arxiu històric; per a producció caldria una versió més nova d'Uptime Kuma.
- No s'ha comprovat l'accés a la interfície web des d'un navegador del client (pendent).

## 7. Resolució de problemes
| Símptoma | Causa | Solució |
|---|---|---|
| El `build` falla a `apt-get` amb errors 404 | La imatge base és Debian 10 sense repositoris normals | El `Dockerfile` usa `archive.debian.org`; comprovar que no s'ha tret aquest canvi |
| `configura_sondes.py` no es pot connectar | Uptime Kuma encara no ha arrencat | Esperar que `docker compose ps monitor` digui `healthy` |
| Una sonda de la web surt DOWN amb `503` | La base de dades és aturada | `docker start B-N06` i esperar que sigui `healthy` |
| Una sonda surt DOWN sense motiu aparent | Interval massa curt per a un servei lent | Revisar el missatge de la sonda i augmentar l'interval |

## 8. Historial de versions
| Versió | Data | Canvis |
|---|---|---|
| 1.0 | 23/11/2026 | Primera versió: Uptime Kuma, cinc sondes i prova de contingència amb `B-N06` |
