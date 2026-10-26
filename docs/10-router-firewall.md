# Router i firewall (R-N06)

|||
|-|-|
|**Projecte**|P0.0 · Desplegament d'infraestructura|
|**Mòdul**|0379 · Projecte intermodular (ASIX)|
|**Equip**|G06 (ASIXc2B) · identificador N06|
|**Autor**|Hèctor Martí|
|**Versió**|1.0 · 26/10/2026 · Sprint 1|

## Índex

1. [Objectiu i abast](#1-objectiu-i-abast)
2. [Funcionament](#2-funcionament)
3. [Interfícies](#3-interfícies)
4. [Regles del firewall](#4-regles-del-firewall)
5. [Implementació](#5-implementació)
6. [Validació](#6-validació)
7. [Resolució de problemes](#7-resolució-de-problemes)
8. [Historial de versions](#8-historial-de-versions)

## 1. Objectiu i abast

Aquest document descriu el router `R-N06`: com enruta el trànsit entre les tres xarxes, com surt a Internet i quines regles de firewall aplica. L'adreçament i la política completa són a l'[arquitectura](01-arquitectura.md). En aquest sprint es preparen i es validen el reenviament, la sortida a Internet i el firewall (es desplegaran i es provaran al sprint 2); el reenviament de ports cap als serveis de la DMZ s'afegeix quan es desplega cada servei.

## 2. Funcionament

El router és un contenidor Linux creat amb la imatge base, connectat a les tres xarxes. Fa tres feines:

1. **Reenviament (*forwarding*).** Té `net.ipv4.ip_forward=1` (definit a `docker-compose.yml`) i és el *gateway* de tots els equips de la DMZ i de la intranet.
2. **NAT.** Els equips interns surten a Internet amb l'adreça del router gràcies a `MASQUERADE` a la interfície de la xarxa NAT.
3. **Firewall.** `iptables` amb política `FORWARD DROP`: només passa el trànsit permès explícitament.

## 3. Interfícies

|Xarxa|Subxarxa|Adreça del router|
|-|-|-|
|NAT|10.213.3.0/24|10.213.3.2|
|DMZ|10.213.1.0/24|10.213.1.254|
|Intranet|10.213.2.0/24|10.213.2.254|

El nom de la interfície (`eth0`, `eth1`...) no és fix: el script la detecta pel prefix de l'adreça IP de cada xarxa.

## 4. Regles del firewall

Es mostren en l'ordre en què s'apliquen.

|#|Regla|Efecte|
|-|-|-|
|1|Connexions `ESTABLISHED,RELATED`|Deixa tornar les respostes|
|2|Origen intranet, qualsevol destí|La intranet surt a la DMZ i a Internet|
|3|DMZ cap a Internet|Actualitzacions|
|4|Resta de trànsit|Es registra amb el prefix `FW-DROP:` i es descarta|

La DMZ no pot arribar a la resta de la intranet. Si un servei exposat es veiés compromès, no podria saltar a la xarxa interna.

## 5. Implementació

|Fitxer|Contingut|
|-|-|
|`services/router/init.sh`|Ruta per defecte, política, regles de `iptables` i NAT|
|`docker-compose.yml`|Servei `router`: `sysctls`, volum de `init.sh`, comprovació de salut i les tres xarxes|

L'entrypoint de la imatge base executa `/opt/init.sh` en arrencar el contenidor. El `healthcheck` comprova que la regla `MASQUERADE` està aplicada, i el client Linux no arrenca fins que el router està `healthy`.

## 6. Validació

Al sprint 1 el router queda preparat i validat; es desplega i es prova al sprint 2.

```bash
bash -n services/router/init.sh
docker compose config --quiet && echo "compose OK"
docker compose build router
```

Resultat: l'script no té errors de sintaxi, el `docker-compose.yml` és correcte i la imatge es construeix. El `healthcheck` i l'espera del client (`service_healthy`) només es poden comprovar en arrencar els contenidors, per això es verifiquen al sprint 2.

Proves previstes per al sprint 2: sortida a Internet des de `PC-L-N06`, i DMZ amb accés a Internet però sense accés a la intranet.

## 7. Resolució de problemes

|Símptoma|Causa probable|Solució|
|-|-|-|
|El client de la intranet no surt a Internet|El router no ha acabat d'arrencar o no té `ip_forward`|`docker compose ps` (ha d'estar `healthy`) i `docker exec R-N06 sysctl net.ipv4.ip_forward`|
|El router no passa a `healthy`|Les regles d'`init.sh` han fallat|`docker logs R-N06`|
|Cap equip arriba a Internet|La ruta per defecte del router no és correcta|`docker exec R-N06 ip route` (ha de passar per `10.213.3.1`)|
|Un paquet es bloqueja i no se sap per què|La política és `FORWARD DROP`|`docker logs R-N06` o `dmesg` mostren les entrades `FW-DROP:`|

## 8. Historial de versions

|Versió|Data|Canvis|
|-|-|-|
|1.0|26/10/2026|Primera versió: reenviament, NAT i firewall del router|

