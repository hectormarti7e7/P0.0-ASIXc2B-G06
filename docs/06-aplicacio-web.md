# Aplicació web (W-N06)

| | |
|---|---|
| **Projecte** | P0.0 · Desplegament d'infraestructura |
| **Mòdul** | 0379 · Projecte intermodular (ASIX) |
| **Equip** | G06 (ASIXc2B) · identificador N06 |
| **Autor** | Josep Pérez |
| **Versió** | 1.0 · 22/11/2026 · Sprint 2 |

## Índex
1. [Objectiu i abast](#1-objectiu-i-abast)
2. [Característiques](#2-característiques)
3. [Implementació](#3-implementació)
4. [Seguretat](#4-seguretat)
5. [Comprovacions](#5-comprovacions)
6. [Pendent](#6-pendent)
7. [Historial de versions](#7-historial-de-versions)

## 1. Objectiu i abast
Aquest document descriu l'aplicació Flask que mostra el contingut de la base de dades `equipaments` ([document 03](03-bbdd-mysql.md)) carregada amb el CSV ([document 05](05-carrega-csv.md)). L'aplicació s'executa al contenidor `W-N06` de la DMZ. El servidor nginx que la publicarà a Internet és tasca de Hèctor Martí i es documentarà al seu document.

## 2. Característiques
| Element | Valor |
|---|---|
| Contenidor | `W-N06`, imatge construïda sobre la imatge base amb `gunicorn`, `python3-flask` i `python3-pymysql` |
| Xarxa i adreça | DMZ · 10.213.1.10 (gateway: el router, 10.213.1.254) |
| Servidor | `gunicorn` amb 2 processos, port 5000 |
| Base de dades | `B-N06` (10.213.2.10:3306), usuari `bchecker` |
| Ús | Lectura: llista les taules, mostra les files amb paginació (50) i permet cercar |

## 3. Implementació
| Fitxer | Contingut |
|---|---|
| `services/web/app/app.py` | L'aplicació. Rutes: `/` (taules i nombre de files), `/taula/<nom>` (files, cerca `?q=` i pàgina `?p=`) i `/health` (comprovació de la connexió amb la BBDD) |
| `docker-compose.yml` | Servei `web`: build, variables de connexió (`DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS`), el codi muntat en només lectura i el `healthcheck` sobre `/health` |
| `services/router/init.sh` | Regla `FORWARD` que deixa la DMZ arribar a la BBDD, només pel TCP 3306 |

Les columnes de la taula no es porten escrites al codi: l'aplicació les llegeix de la base de dades (`SHOW COLUMNS`). Així continua funcionant si el CSV de Open Data BCN canvia de columnes en tornar a carregar-lo.

El servei `web` depèn del router i de la BBDD (`depends_on` amb `service_healthy`), de manera que no s'arrenca fins que tots dos són a punt.

### 3.1 Regla del firewall
```
iptables -A FORWARD -i "$IF_DMZ" -o "$IF_INT" -p tcp -d 10.213.2.10 --dport 3306 -j ACCEPT
```
És la regla 3 de la [política del firewall](01-arquitectura.md#6-política-del-firewall). Les respostes tornen per la regla de connexions establertes.

## 4. Seguretat
| Mesura | Efecte |
|---|---|
| Nom de taula validat | `/taula/<nom>` només accepta un nom que existeix a `SHOW TABLES`; la resta dona 404. No es construeix cap consulta amb un nom arbitrari |
| Cerca amb paràmetres | El text de cerca s'envia a la BBDD com a paràmetre (`LIKE %s`), mai concatenat a la consulta |
| Sortida escapada | Tot el que es mostra (valors, noms de columna, text de cerca) s'escapa abans de posar-lo a l'HTML |
| Només lectura | L'aplicació només fa `SELECT` i `SHOW` |
| Firewall | La DMZ només arriba a la BBDD pel 3306; la resta de ports i equips de la intranet queden bloquejats |
| Codi en només lectura | El contenidor munta `services/web/app` amb `:ro` |

**Limitació:** l'aplicació usa l'usuari `bchecker`, que té tots els permisos sobre `equipaments` (és el que demana l'enunciat). En un entorn real hi hauria un usuari només amb `SELECT`.

## 5. Comprovacions
S'executen des de l'equip dels serveis, dins del contenidor (22/11/2026), perquè els clients d'`itb 6` encara no tenen ruta cap a la DMZ.

| # | Prova | Ordre | Resultat obtingut |
|---|---|---|---|
| 1 | Connexió amb la BBDD | `docker exec W-N06 curl -s -i http://127.0.0.1:5000/health` | `HTTP/1.1 200 OK` |
| 2 | Portada | `docker exec W-N06 curl -s http://127.0.0.1:5000/` | Mostra la taula amb **2709** files |
| 3 | Cerca | `.../taula/equipaments_educacio?q=Gracia` | `207 files coincidents` |
| 4 | Taula inexistent | `.../taula/inventada` | `404` |
| 5 | DMZ cap a un port no permès de la BBDD | `docker exec W-N06 bash -c 'echo > /dev/tcp/10.213.2.10/22'` | Bloquejat (la connexió no s'estableix) |

Les proves 1 a 3 demostren que la web arriba a la BBDD a través del router (regla DMZ → 3306). La prova 5 demostra que no s'obre res més.

## 6. Pendent
- Publicar l'aplicació a Internet amb nginx al davant (Hèctor Martí) i la regla del router per als ports 80 i 443.
- Provar-la des d'un navegador del client quan nginx estigui desplegat.

## 7. Historial de versions
| Versió | Data | Canvis |
|---|---|---|
| 1.0 | 22/11/2026 | Primera versió: aplicació, regla DMZ → BBDD i proves |
