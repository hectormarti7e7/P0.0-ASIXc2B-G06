# Aplicació web (W-N06)

| | |
|---|---|
| **Projecte** | P0.0 · Desplegament d'infraestructura |
| **Mòdul** | 0379 · Projecte intermodular (ASIX) |
| **Equip** | G06 (ASIXc2B) · identificador N06 |
| **Autor** | Josep Pérez |
| **Versió** | 1.2 · 22/11/2026 · Sprint 2 |

## Índex
1. [Objectiu i abast](#1-objectiu-i-abast)
2. [Característiques](#2-característiques)
3. [Implementació](#3-implementació)
4. [Seguretat](#4-seguretat)
5. [Comprovacions](#5-comprovacions)
6. [Pendent](#6-pendent)
7. [Historial de versions](#7-historial-de-versions)

## 1. Objectiu i abast
Aquest document descriu l'aplicació Flask que mostra el contingut de la base de dades `equipaments` ([document 03](03-bbdd-mysql.md)) carregada amb el CSV ([document 03](03-bbdd-mysql.md#5-càrrega-del-csv)). L'aplicació s'executa al contenidor `W-N06` de la DMZ, amb nginx al davant que la publica pels ports 80 i 443.

## 2. Característiques
| Element | Valor |
|---|---|
| Contenidor | `W-N06`, imatge construïda sobre la imatge base amb `nginx`, `openssl`, `gunicorn`, `python3-flask` i `python3-pymysql` |
| Xarxa i adreça | DMZ · 10.213.1.10 (gateway: el router, 10.213.1.254) |
| Servidor d'aplicació | `gunicorn` amb 2 processos, a `127.0.0.1:5000` i `0.0.0.0:5000` dins del contenidor |
| Cara pública | nginx: port 80 (redirigeix a HTTPS) i port 443 (HTTPS amb certificat autosignat) |
| Base de dades | `B-N06` (10.213.2.10:3306), usuari `bchecker` |
| Ús | Lectura: llista les taules, mostra les files amb paginació (50) i permet cercar |
| Autenticació | HTTP Basic: sense credencials vàlides respon **401**. Usuari i contrasenya de la pràctica (`bchecker`), definits a les variables `APP_USER` i `APP_PASS` del `docker-compose.yml` |

## 3. Implementació
| Fitxer | Contingut |
|---|---|
| `services/web/app/app.py` | L'aplicació. Rutes: `/` (taules i nombre de files), `/taula/<nom>` (files, cerca `?q=` i pàgina `?p=`) i `/health` (comprovació de la connexió amb la BBDD, sense autenticació perquè no mostra dades i la usa el `healthcheck`). La resta de rutes demanen autenticació |
| `services/web/nginx.conf` | Redirecció de HTTP a HTTPS, HTTPS (TLS 1.2 i 1.3), capçaleres de seguretat i `proxy_pass` cap a gunicorn |
| `services/web/init.sh` | Genera el certificat autosignat si no existeix, instal·la la configuració i arrenca nginx abans de gunicorn |
| `docker-compose.yml` | Servei `web`: build, variables de connexió (`DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS`), els fitxers muntats en només lectura i el `healthcheck` (gunicorn i nginx). El router publica els ports 80 i 443 |
| `services/router/init.sh` | Regla `FORWARD` que deixa la DMZ arribar a la BBDD (TCP 3306); DNAT i regla `FORWARD` dels ports 80 i 443 cap a `W-N06`; `MASQUERADE` cap a la DMZ perquè la web respongui sempre al router |

Les columnes de la taula no es porten escrites al codi: l'aplicació les llegeix de la base de dades (`SHOW COLUMNS`). Així continua funcionant si el CSV de Open Data BCN canvia de columnes en tornar a carregar-lo.

El servei `web` depèn del router i de la BBDD (`depends_on` amb `service_healthy`), de manera que no s'arrenca fins que tots dos són a punt.

### 3.1 Regles del firewall
```
iptables -A FORWARD -i "$IF_DMZ" -o "$IF_INT" -p tcp -d 10.213.2.10 --dport 3306 -j ACCEPT
iptables -A FORWARD -i "$IF_NAT" -o "$IF_DMZ" -p tcp -d 10.213.1.10 -m multiport --dports 80,443 -j ACCEPT
iptables -t nat -A PREROUTING -i "$IF_NAT" -p tcp --dport 80  -j DNAT --to-destination 10.213.1.10:80
iptables -t nat -A PREROUTING -i "$IF_NAT" -p tcp --dport 443 -j DNAT --to-destination 10.213.1.10:443
```
Són les regles 3, 6 i la redirecció de ports de la [política del firewall](01-arquitectura.md#6-política-del-firewall). Les respostes tornen per la regla de connexions establertes. Perquè Docker entregui els ports 80 i 443 per la pota NAT del router, la xarxa `nat` du `gw_priority: 1` (vegeu el [document 07](07-servidor-ssh.md), apartat 4.2).

## 4. Seguretat
| Mesura | Efecte |
|---|---|
| Autenticació HTTP Basic | Cada petició (excepte `/health`) ha de dur credencials vàlides; si no, 401 amb la capçalera `WWW-Authenticate`. La comparació és de temps constant (`hmac.compare_digest`) |
| Nom de taula validat | `/taula/<nom>` només accepta un nom que existeix a `SHOW TABLES`; la resta dona 404. No es construeix cap consulta amb un nom arbitrari |
| Cerca amb paràmetres | El text de cerca s'envia a la BBDD com a paràmetre (`LIKE %s`), mai concatenat a la consulta |
| Sortida escapada | Tot el que es mostra (valors, noms de columna, text de cerca) s'escapa abans de posar-lo a l'HTML |
| HTTPS | HTTP redirigeix a HTTPS; només TLS 1.2 i 1.3. El certificat és autosignat: el navegador avisa i s'ha d'acceptar manualment |
| Capçaleres | `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY` i `server_tokens off` (no es mostra la versió d'nginx) |
| Només lectura | L'aplicació només fa `SELECT` i `SHOW` |
| Firewall | La DMZ només arriba a la BBDD pel 3306; la resta de ports i equips de la intranet queden bloquejats |
| Codi en només lectura | El contenidor munta `services/web/app` amb `:ro` |

**Limitació:** HTTP Basic envia les credencials codificades en Base64, no xifrades; per això només s'han d'usar per HTTPS (nginx redirigeix el port 80 al 443). L'aplicació usa l'usuari `bchecker`, que té tots els permisos sobre `equipaments` (és el que demana l'enunciat). En un entorn real hi hauria un usuari només amb `SELECT`.

## 5. Comprovacions
### 5.1 Aplicació i BBDD, des del contenidor
S'executen des de l'equip dels serveis, dins del contenidor (22/11/2026).

| # | Prova | Ordre | Resultat obtingut |
|---|---|---|---|
| 1 | Connexió amb la BBDD | `docker exec W-N06 curl -s -i http://127.0.0.1:5000/health` | `HTTP/1.1 200 OK` |
| 2 | Portada | `docker exec W-N06 curl -s http://127.0.0.1:5000/` | Mostra la taula amb **2709** files |
| 3 | Cerca | `.../taula/equipaments_educacio?q=Gracia` | `207 files coincidents` |
| 4 | Taula inexistent | `.../taula/inventada` | `404` |
| 5 | DMZ cap a un port no permès de la BBDD | `docker exec W-N06 bash -c 'echo > /dev/tcp/10.213.2.10/22'` | Bloquejat (la connexió no s'estableix) |

Les proves 1 a 3 demostren que la web arriba a la BBDD a través del router (regla DMZ → 3306). La prova 5 demostra que no s'obre res més.

### 5.2 Web publicada, des del client Linux (`PC-L-N06`)
El client arriba a l'equip dels serveis (`192.168.50.22`) i d'allà al router i a `W-N06`. Resultats del 22/11/2026:

| # | Prova | Ordre | Resultat obtingut |
|---|---|---|---|
| 1 | HTTP redirigeix | `curl -sI http://192.168.50.22/` | `301 Moved Permanently` |
| 2 | Estat de l'aplicació per HTTPS | `curl -sk https://192.168.50.22/health` | `ok` |
| 3 | Portada | `curl -sk --user bchecker:bchecker121 https://192.168.50.22/` | **2709** files |
| 4 | Cerca | `curl -sk --user bchecker:bchecker121 'https://192.168.50.22/taula/equipaments_educacio?q=Gracia'` | `207 files coincidents` |
| 5 | Capçaleres de seguretat | `curl -skI https://192.168.50.22/` | `X-Content-Type-Options: nosniff` i `X-Frame-Options: DENY` (comprovat abans d'afegir l'autenticació) |

L'opció `-k` d'`curl` accepta el certificat autosignat. Les proves 3 i 4 es van fer abans de l'autenticació i es van repetir amb credencials (apartat 5.3), amb el mateix resultat.

### 5.3 Autenticació (22/11/2026)
| # | Prova | Ordre | Esperat | Obtingut |
|---|---|---|---|---|
| 1 | Sense credencials | `curl -sk -o /dev/null -w '%{http_code}' https://192.168.50.22/` | 401 | `401`, amb `WWW-Authenticate: Basic realm="P0.0 N06"` |
| 2 | Taula sense credencials | `curl ... https://192.168.50.22/taula/equipaments_educacio` | 401 | `401` |
| 3 | Contrasenya incorrecta | `curl ... --user bchecker:mal https://192.168.50.22/` | 401 | `401` |
| 4 | Credencials vàlides | `curl ... --user bchecker:bchecker121 https://192.168.50.22/` | 200 i dades | `200`, **2709** files i `207 files coincidents` en cercar `Gracia` |
| 5 | `/health` obert | `curl -sk https://192.168.50.22/health` | `ok` | `ok` |

## 6. Pendent
- Provar la web amb un navegador gràfic del client i guardar-ne la captura.
- Provar-la des de la xarxa d'Internet real quan estigui autoritzat obrir els ports 80 i 443 de l'equip.

## 7. Historial de versions
| Versió | Data | Canvis |
|---|---|---|
| 1.0 | 22/11/2026 | Primera versió: aplicació, regla DMZ → BBDD i proves |
| 1.1 | 22/11/2026 | nginx al davant (HTTP→HTTPS), ports 80 i 443 al router i proves des del client |
| 1.2 | 22/11/2026 | Autenticació HTTP Basic (401 sense credencials) i proves |
