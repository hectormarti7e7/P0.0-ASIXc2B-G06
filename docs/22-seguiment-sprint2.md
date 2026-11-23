# Seguiment i evidències del sprint 2

| | |
|---|---|
| **Projecte** | P0.0 · Desplegament d'infraestructura |
| **Mòdul** | 0379 · Projecte intermodular (ASIX) |
| **Equip** | G06 (ASIXc2B) · identificador N06 |
| **Autors** | Josep Pérez, Hèctor Martí |
| **Versió** | 1.1 · 23/11/2026 · Sprint 2 |

## Índex
1. [Objectiu i criteri](#1-objectiu-i-criteri)
2. [Estat de les tasques](#2-estat-de-les-tasques)
3. [Requisits de l'enunciat](#3-requisits-de-lenunciat)
4. [Usuari `bchecker` a tots els contenidors](#4-usuari-bchecker-a-tots-els-contenidors)
5. [Integració al repositori](#5-integració-al-repositori)
6. [Desviacions respecte de la planificació](#6-desviacions-respecte-de-la-planificació)
7. [Pendent](#7-pendent)
8. [Historial de versions](#8-historial-de-versions)

## 1. Objectiu i criteri
Aquest document és la llista de control del sprint 2: què estava previst, en quin estat és cada tasca i cada requisit de l'enunciat, i on es pot comprovar. Es manté actualitzat amb l'estat real; no es marca res com a fet sense una prova al document indicat. La planificació general és al [pla del projecte](16-pla-projecte.md); les proves, amb el seu resultat, són al [pla de proves](20-pla-proves.md); les limitacions conegudes, al [document de riscos](17-prevencio-riscos.md).

| Estat | Significat |
|---|---|
| Fet / Verificat | Desenvolupat i provat, amb l'ordre executada i el resultat guardat al document indicat |
| En curs / Configurat | Hi ha treball fet o configuració, però no s'ha comprovat tot el funcionament |
| Pendent | No està fet o no hi ha prova suficient |

Un servei no es dona per operatiu només perquè existeixi la imatge o el fitxer de configuració.

## 2. Estat de les tasques
Les dates són les de la prova documentada. Les hores dedicades no es registren aquí: són al ProofHub.

| # | Tasca | Estat | Desenvolupament i proves | Data | Document |
|---|---|---|---|---|---|
| 1 | Base de dades MySQL `B-N06` | Fet | Josep Pérez | 16/11/2026 | [03](03-bbdd-mysql.md) |
| 2 | Disseny de la xarxa dels clients (`itb 6`) i *script* de la xarxa | Fet | Josep Pérez | 18/11/2026 | [04](04-clients-isard.md), [01](01-arquitectura.md) |
| 3 | Càrrega del CSV a MySQL | Fet | Josep Pérez | 19/11/2026 | [05](05-carrega-csv.md) |
| 4 | Client Linux (VM a Isard) | Fet | Josep Pérez | 20/11/2026 | [04](04-clients-isard.md) |
| 5 | Servidor SSH (port 2222, només clau pública) | Fet | Josep Pérez | 22/11/2026 | [07](07-servidor-ssh.md) |
| 6 | Servidor web nginx (HTTP, HTTPS) | Fet | Josep Pérez | 22/11/2026 | [06](06-aplicacio-web.md) |
| 7 | Aplicació Flask amb autenticació (401) | Fet | Josep Pérez | 22/11/2026 | [06](06-aplicacio-web.md) |
| 8 | Servidor DNS | Fet | Josep Pérez | 22/11/2026 | [08](08-servidor-dns.md) |
| 9 | Servidor FTP | Fet | Josep Pérez | 22/11/2026 | [24](24-servidor-ftp.md) |
| 10 | Servidor DHCP | Fet | Josep Pérez | 22/11/2026 | [25](25-servidor-dhcp.md) |
| 11 | Monitorització amb Uptime Kuma | Fet | Josep Pérez | 23/11/2026 | [26](26-monitoritzacio.md) |
| 12 | Client Windows (VM a Isard) | **Pendent** de documentar | Hèctor Martí (té la màquina virtual) | — | [04](04-clients-isard.md) |
| 13 | Seguiment i evidències | En curs | Josep Pérez | 23/11/2026 | Aquest document |
| 14 | Riscos i prevenció, manual i pla de proves | En curs | Josep Pérez | — | [17](17-prevencio-riscos.md), [02](02-desplegament-client.md), [20](20-pla-proves.md) |
| 15 | Diari de treball | **Pendent** | Josep Pérez i Hèctor Martí | — | — |

## 3. Requisits de l'enunciat
| Requisit | Estat | Evidència | Document |
|---|---|---|---|
| Router `R-NCC` amb tres xarxes (DMZ, intranet i NAT) | Verificat | `R-N06` apareix com a `healthy` i enruta entre les tres xarxes: els serveis de la DMZ arriben a la BBDD de la intranet i els clients hi arriben pel router | [01](01-arquitectura.md), [10](10-router-firewall.md) |
| Servidor web `W-NCC` | Verificat | HTTP redirigeix a HTTPS (`301`); `/health` respon `ok` | [06](06-aplicacio-web.md) |
| SSH | Verificat | Entra amb clau pública al port 2222; sense clau i com a `root`, `Permission denied (publickey)` | [07](07-servidor-ssh.md) |
| BBDD `B-NCC` amb MySQL i usuari `bchecker` | Verificat | Base `equipaments`, accés amb `bchecker`, persistència al volum | [03](03-bbdd-mysql.md) |
| Càrrega del CSV d'equipaments d'educació | Verificat | 2.709 files carregades a `equipaments_educacio` | [05](05-carrega-csv.md) |
| DHCP | Verificat | `nmap --script broadcast-dhcp-discover` mostra una oferta de `10.213.2.67` (`10.213.2.117`, router i DNS correctes) | [25](25-servidor-dhcp.md) |
| DNS (ha de resoldre `R-NCC` i `R` pel router) | Verificat | `R-N06` i `R` resolen `10.213.2.254`, des d'un contenidor i des del client Linux | [08](08-servidor-dns.md) |
| FTP `F-NCC` | Verificat | Llistat, descàrrega i pujada a `pujades`; denegats: pujada a l'arrel, contrasenya incorrecta i `root` | [24](24-servidor-ftp.md) |
| Monitor de xarxa | Verificat | Cinc sondes en `ACTIU (UP)`; amb `docker stop B-N06` la sonda de MySQL passa a `CAIGUDA (DOWN)` i es recupera amb `docker start B-N06` | [26](26-monitoritzacio.md) |
| Client Linux | Verificat | Connexió amb la intranet, consulta a MySQL i `su bchecker` (20/11/2026) | [04](04-clients-isard.md) |
| Client Windows | **Pendent** | La màquina virtual està configurada (segons l'equip, amb la IP `192.168.50.23`, diferent de la `192.168.50.60` prevista als documents 01 i 04), però no hi ha cap prova al repositori | [04](04-clients-isard.md) |
| Aplicació que mostra les taules carregades | Verificat | Portada amb **2709** files i cerca (`207 files coincidents` per `Gracia`), amb autenticació | [06](06-aplicacio-web.md) |
| Usuari `bchecker`/`bchecker121` a tots els sistemes | Verificat (contenidors i client Linux) | `id bchecker` als vuit contenidors (apartat 4); client Linux amb `su bchecker`. Al client Windows, pendent | [02](02-desplegament-client.md), [04](04-clients-isard.md) |
| Diagrama de l'arquitectura | Verificat | `docs/img/arquitectura-N06.svg`, a la figura 1 del document d'arquitectura | [01](01-arquitectura.md) |
| Repositori Git amb la configuració i la documentació | Verificat | Repositori `P0.0-ASIXc2B-G06`, una branca per tasca i fusions per *pull request* | [14](14-control-versions.md) |
| Arbre de documentació en Markdown | Verificat | `docs/` amb índex a `docs/README.md` | [README](README.md) |
| Planificació a ProofHub | **Pendent** | Fora del repositori: cal actualitzar-lo (estat de les tasques, hores i comentaris) | [16](16-pla-projecte.md) |

## 4. Usuari `bchecker` a tots els contenidors
L'enunciat exigeix un usuari `bchecker` a tots els sistemes. Es comprova des de l'equip dels serveis (23/11/2026):

```bash
for c in R-N06 S-N06 W-N06 F-N06 B-N06 DNS-N06 DHCP-N06 MON-N06; do
  printf '%s: ' "$c"; docker exec "$c" id bchecker 2>&1 | head -1
done
```

| Contenidor | Resultat obtingut |
|---|---|
| `R-N06`, `S-N06`, `W-N06`, `F-N06`, `B-N06`, `DNS-N06` i `DHCP-N06` | `uid=1000(bchecker) gid=1000(bchecker) groups=1000(bchecker),27(sudo)` |
| `MON-N06` | `uid=1001(bchecker) gid=1001(bchecker) groups=1001(bchecker),27(sudo)` (l'identificador és diferent de la resta) |

L'usuari existeix en els vuit contenidors i pertany al grup `sudo`. Aquesta prova només comprova que l'usuari existeix; la contrasenya `bchecker121` s'ha comprovat a la BBDD, al client Linux (`su bchecker`), a l'FTP i a l'aplicació web, i la d'Uptime Kuma s'ha fet servir per crear les sondes.

## 5. Integració al repositori
El treball es fusiona a `main` amb *pull requests*, una branca per tasca (`sprint2/<tasca>`). Els serveis DNS, FTP, DHCP i monitor es van desenvolupar i provar a l'equip de Josep Pérez; els *commits* i les *pull requests* d'aquests quatre serveis els fa Hèctor Martí, a partir de fitxers de pedaç (`git apply`), de manera que l'historial reflecteix qui ha integrat cada canvi.

| Branca | Contingut | Estat de la fusió |
|---|---|---|
| `sprint2/servidor-ssh` | SSH | Fusionada (PR #8) |
| `sprint2/app-flask` | Aplicació Flask | Fusionada (PR #9) |
| `sprint2/nginx` | nginx i ports 80 i 443 | Fusionada (PR #10) |
| `sprint2/flask-auth` | Autenticació 401 | Fusionada (PR #11) |
| `sprint2/dns` | DNS | Pendent (Hèctor Martí) |
| `sprint2/ftp` | FTP | Pendent (Hèctor Martí) |
| `sprint2/dhcp` | DHCP | Pendent (Hèctor Martí) |
| `sprint2/monitor` | Monitorització | Pendent (Hèctor Martí) |

Les fusions anteriors (base de dades, xarxa dels clients, càrrega del CSV i client Linux) són els PR #3 a #7.

## 6. Desviacions respecte de la planificació
| Desviació | Causa | Resolució |
|---|---|---|
| El projecte estava previst per al 18/11 (data indicativa) i les tasques del sprint 2 s'han acabat entre el 20/11 i el 23/11 | Les dificultats de xarxa amb Isard van consumir temps | Es continua treballant amb el calendari real |
| El disseny de la xarxa dels clients va canviar (de `ipvlan` a enrutament a través de l'equip dels serveis) | Isard filtra les MAC dels ponts i `ipvlan` impedia que el trànsit passés pel router | Disseny documentat al [document 01](01-arquitectura.md), apartat 4.1 |
| FTP sense TLS | `vsftpd` es tancava en activar-lo, sense missatge d'error | Documentat com a limitació al [document 24](24-servidor-ftp.md) |
| El client Windows no està documentat | La màquina virtual és a l'equip de Hèctor Martí | Pendent |

## 7. Pendent
- **Client Windows:** configuració, quatre *pings* i ordres PowerShell, amb el resultat observat; unificar la seva adreça IP als documents 01 i 04.
- **Fusió dels quatre PR** de DNS, FTP, DHCP i monitor.
- **ProofHub:** tancar les tasques completades, registrar les hores i afegir els comentaris.
- **Diari de treball:** redactar-lo amb les dates reals de cada sessió.
- **Proves pendents del [pla de proves](20-pla-proves.md):** F9, C4, C5 i A1.
- **Mesures de rendiment i disponibilitat** del [document 15](15-criteris-rendiment-disponibilitat.md): només hi ha D4 i P5.
- **Documentació per al client** i documents 12 (recopilació d'informació) i 13 (anàlisi de mercat), als quals fa referència l'[estudi previ 11](11-estudi-previ-web-monitor-firewall.md).
- **Persistència de les regles d'`iptables`:** no sobreviuen a un reinici (risc T2 del [document 17](17-prevencio-riscos.md)).

## 8. Historial de versions
| Versió | Data | Canvis |
|---|---|---|
| 1.0 | 23/11/2026 | Primera versió: estat de les tasques, integració, desviacions i pendent |
| 1.1 | 23/11/2026 | S'hi integren els requisits de l'enunciat i la comprovació de `bchecker` (abans en un document d'evidències a part); les proves i les limitacions passen a referenciar els documents 20 i 17 |
