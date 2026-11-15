# Criteris de rendiment i disponibilitat

| | |
|---|---|
| **Projecte** | P0.0 · Desplegament d'infraestructura |
| **Mòdul** | 0379 · Projecte intermodular (ASIX) |
| **Equip** | G06 (ASIXc2B) · identificador N06 |
| **Autor** | Josep Pérez |
| **Versió** | 1.0 · 15/11/2026 · Sprint 1 |

## Índex
1. [Objectiu i abast](#1-objectiu-i-abast)
2. [Definicions](#2-definicions)
3. [Criteris](#3-criteris)
4. [Com es mesura](#4-com-es-mesura)
5. [Estat d'implementació](#5-estat-dimplementació)
6. [Registre de mesures](#6-registre-de-mesures)
7. [Historial de versions](#7-historial-de-versions)

## 1. Objectiu i abast
Aquest document defineix els criteris de rendiment i de disponibilitat de la infraestructura, amb objectius mesurables i amb la manera de comprovar-los. Els valors són els objectius de l'equip. Es revisen amb les primeres mesures reals, que es fan quan els serveis estan desplegats (sprints 2 i 3), i els resultats es recullen a l'apartat 6.

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
| P1 | Latència entre contenidors d'una mateixa xarxa | 5 ms o menys de mitjana i 0 % de paquets perduts | Xarxes |
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
```bash
docker exec PC-L-N06 ping -c 20 10.213.2.254
docker exec PC-L-N06 ping -c 20 1.1.1.1
docker exec PC-L-N06 ip route show default
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
| `healthcheck` del router (regla `MASQUERADE`) i espera del client fins que el router és `healthy` | Fet |
| `healthcheck` de la BBDD | Previst al sprint 2 |
| Sondes d'Uptime Kuma per servei | Previst al sprint 2 |
| Proves de càrrega amb `ab` i proves de recuperació | Previstes als sprints 2 i 3 |

## 6. Registre de mesures
Es completa amb cada mesura feta.

| Data | Criteri | Valor mesurat | Objectiu | Compleix | Observacions |
|---|---|---|---|---|---|
| | | | | | |

## 7. Historial de versions
| Versió | Data | Canvis |
|---|---|---|
| 1.0 | 15/11/2026 | Primera versió: criteris, mètode de mesura i estat d'implementació |
