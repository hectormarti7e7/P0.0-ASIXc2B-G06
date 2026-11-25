# Pla del projecte i prevenció de riscos

| | |
|---|---|
| **Projecte** | P0.0 · Desplegament d'infraestructura |
| **Mòdul** | 0379 · Projecte intermodular (ASIX) |
| **Equip** | G06 (ASIXc2B) · identificador N06 |
| **Autor** | Josep Pérez |
| **Versió** | 1.5 · 25/11/2026 · Sprint 2 |

## Índex
1. [Objectiu i abast](#1-objectiu-i-abast)
2. [Fases i sprints](#2-fases-i-sprints)
3. [Tasques i responsables](#3-tasques-i-responsables)
4. [Recursos](#4-recursos)
5. [Dedicació](#5-dedicació)
6. [Riscos tècnics](#6-riscos-tècnics)
7. [Riscos laborals](#7-riscos-laborals)
8. [Seguiment](#8-seguiment)
9. [Historial de versions](#9-historial-de-versions)

## 1. Objectiu i abast
Aquest document recull com s'organitza el projecte: les fases, qui fa cada tasca, els recursos necessaris, la dedicació prevista i els riscos (tècnics i laborals) amb la seva prevenció. El projecte dura 6 setmanes, fins al 18/11/2026, repartides en 3 sprints quinzenals. Les dates i l'estat de cada tasca són a ProofHub, que és la font de referència.

## 2. Fases i sprints
| Fase | Sprint | Objectiu | Entregables |
|---|---|---|---|
| 1. Preparació | 1 | Base de la infraestructura i decisions tècniques | ProofHub i backlog, repositori, diagrama, estudis previs, imatge base, tres xarxes, router i firewall base, documentació inicial |
| 2. Serveis | 2 | Desplegar els serveis i els clients | BBDD amb el CSV carregat, web i aplicació de proves, SSH, DHCP, DNS, FTP, monitor, client Linux i client Windows |
| 3. Integració i tancament | 3 | Connectar els serveis, provar-los i documentar-los | Regles del firewall i reenviament de ports cap als serveis, proves de rendiment i disponibilitat, documentació per al client i per a l'administrador, defensa |

## 3. Tasques i responsables
### Sprint 1
| Tasca | Responsable |
|---|---|
| Crear el projecte a ProofHub, amb el backlog i els 3 sprints | Josep Pérez |
| Repositori GitHub, clau SSH, col·laboradors, branques i plantilla de PR | Hèctor Martí |
| Estudi previ: contenidors o màquines virtuals, MySQL o MariaDB | Josep Pérez |
| Estudi previ: nginx o Apache, Uptime Kuma o Zabbix, iptables o nftables | Hèctor Martí |
| Diagrama d'arquitectura | Josep Pérez |
| Taula d'adreçament i política de firewall | Hèctor Martí |
| Imatge base i `docker-compose` amb les 3 xarxes | Josep Pérez |
| Router R-N06: reenviament, NAT i firewall | Hèctor Martí |

### Sprint 2
| Tasca | Responsable |
|---|---|
| BBDD MySQL amb l'usuari `bchecker` | Josep Pérez |
| Client Linux (PC-L-N06): màquina virtual a Isard, connectada per itb 6 | Josep Pérez |
| Connexió dels clients amb la intranet per itb 6 (enrutament) | Josep Pérez |
| Script de càrrega del CSV d'equipaments | Josep Pérez |
| Servidor SSH | Josep Pérez |
| Aplicació web Flask que mostra les taules | Josep Pérez |
| Servidor web nginx base | Hèctor Martí |
| DHCP de la intranet | Hèctor Martí |
| Monitor de xarxes (Uptime Kuma) amb sondes | Hèctor Martí |
| Client Windows | Hèctor Martí |
| DNS (ha de resoldre `R-N06` i `R`) i FTP | Per repartir |

### Sprint 3
| Tasca | Responsable |
|---|---|
| Regles del firewall (BBDD, DNS) i reenviament de ports | Per repartir |
| Proves de rendiment i disponibilitat | Per repartir |
| Documentació per al client i per a l'administrador | Per repartir |
| Preparació de la defensa | Josep Pérez i Hèctor Martí |

## 4. Recursos
| Tipus | Recurs |
|---|---|
| Persones | Josep Pérez i Hèctor Martí |
| Maquinari | Una màquina virtual d'Isard amb Docker (Ubuntu 24) i dues màquines virtuals més per als clients (Linux i Windows), totes tres connectades a la xarxa `itb 6` |
| Programari d'infraestructura | Docker Engine 24 o superior, Docker Compose v2, `iptables` |
| Serveis | nginx i Flask amb gunicorn, MySQL 8.0, dnsmasq (DNS i DHCP), vsftpd, OpenSSH, Uptime Kuma |
| Gestió | ProofHub (tasques, hores i diari de treball), GitHub (codi i documentació) |
| Cost | Cap llicència de pagament. El client Windows depèn de la versió disponible per a l'avaluació |

## 5. Dedicació
L'enunciat fixa 5 hores setmanals per persona, és a dir, 10 hores per sprint.

| Sprint | Hores per persona | Hores de l'equip |
|---|---|---|
| 1 | 10 | 20 |
| 2 | 10 | 20 |
| 3 | 10 | 20 |
| **Total** | **30** | **60** |

## 6. Riscos tècnics
La probabilitat i l'impacte són valoracions qualitatives de l'equip (Baixa, Mitjana, Alta); no provenen de cap mesura. L'estat només és «Verificat» quan hi ha una prova al repositori.

| # | Risc | Prob. | Impacte | Prevenció o mitigació | Estat |
|---|---|---|---|---|---|
| T1 | Docker 28 o superior descarta paquets de xarxes a l'host (regles *raw*) i el trànsit dels clients no arriba a la intranet | Alta | Alt | Mode `nat-unprotected` a la xarxa `intranet` i *script* `scripts/xarxa-clients.sh`, que afegeix regles a `DOCKER-USER` | Configurat; vegeu docs [01](01-arquitectura.md) i [04](04-clients-isard.md) |
| T2 | Les regles `iptables` de l'*script* de xarxa no persisteixen després d'un reinici de l'host | Alta | Mitjà | Tornar a executar `sudo ./scripts/xarxa-clients.sh` després de cada reinici | Limitació documentada; no automatitzat |
| T3 | Un fitxer de muntatge (*bind mount*) inexistent es crea com a directori propietat de `root` i el servei no arrenca | Mitjana | Mitjà | Comprovar que els fitxers existeixen abans de `docker compose up`; eliminar-los amb `sudo rmdir` | Verificat (trobat i corregit el 22/11/2026) |
| T4 | Editar un fitxer muntat no reinicia el contenidor i el canvi no s'aplica | Mitjana | Baix | `docker compose up -d --force-recreate <servei>` | Verificat |
| T5 | El port publicat del router arriba per la pota DMZ i la connexió SSH és refusada | Mitjana | Alt | `gw_priority: 1` a la xarxa `nat` i `MASQUERADE` cap a la DMZ | Verificat (22/11/2026) |
| T6 | FTP sense TLS: credencials i dades viatgen en clar | Alta | Mitjà | Limitació acceptada i documentada (`vsftpd` sortia sense missatge amb `ssl_enable=YES`); fer servir només dins la xarxa del projecte | Documentat; vegeu doc [24](24-servidor-ftp.md) |
| T7 | El DHCP no arriba als clients de `itb 6` (difusió) | Alta | Baix | Proves fetes en un contenidor de la intranet | Documentat; vegeu doc [25](25-servidor-dhcp.md) |
| T8 | El fitxer CSV és UTF-16 amb 40 columnes i es carrega malament | Mitjana | Mitjà | Càrrega amb `load_csv.py`; verificació amb `--default-character-set=utf8mb4` | Verificat (2.709 files) |
| T9 | El *loader* fa `DROP TABLE IF EXISTS` i esborra dades en tornar a executar-lo | Mitjana | Alt | Còpia amb `mysqldump` abans de tornar a carregar | Documentat; vegeu doc [03](03-bbdd-mysql.md#58-seguretat-i-manteniment) |
| T10 | La imatge d'Uptime Kuma 1.23.16 és Debian 10 (*buster*, fora de suport) i `apt` falla | Alta | Baix | Repositoris d'`archive.debian.org` al `Dockerfile` | Verificat |
| T11 | La web depèn de la base de dades: si `B-N06` cau, l'aplicació deixa de servir dades | Mitjana | Alt | Sonda de monitorització sobre MySQL i prova de caiguda i recuperació | Verificat (23/11/2026) |
| T12 | Tots els serveis depenen d'un únic host (punt únic de fallada) | Baixa | Alt | Cap; risc assumit per l'abast del projecte | Assumit |
| T13 | Credencials per defecte compartides (`bchecker`/`bchecker121`, exigides per l'enunciat) i `bchecker` amb tots els privilegis a la BD | Alta | Alt | S'usen només en aquest entorn de pràctica i no es reutilitzen; la BBDD només és accessible des de la intranet i, pel port 3306, des de la DMZ; accés SSH només per clau; contrasenya de l'aplicació configurable amb `APP_USER`/`APP_PASS` | Parcial; el compte és imposat |
| T14 | Certificats TLS autosignats: el navegador avisa i no hi ha validació d'identitat | Alta | Baix | Acceptat per a l'entorn de proves | Assumit |
| T15 | Uptime Kuma sense notificacions: una caiguda només es veu mirant el tauler | Mitjana | Mitjà | Revisió manual del tauler | Limitació documentada; vegeu doc [26](26-monitoritzacio.md) |
| T16 | Retard per la poca dedicació disponible (10 h per persona i sprint) | Alta | Alt | Tasques petites amb criteri de «feta» a ProofHub, prioritat als requisits de l'enunciat i revisió de l'estat a cada sessió | Definit |
| T17 | El rang de les xarxes Docker xoca amb xarxes existents al servidor (ja va passar amb 172.20.0.0/16) | Mitjana | Mitjà | S'ha fixat 10.213.0.0/16; si torna a passar, es canvien les tres subxarxes del compose ([manual](02-desplegament-client.md), apartat 13) | Resolt |
| T18 | El client Windows no es pot executar com a contenidor Linux | Alta | Mitjà | És una màquina virtual al laboratori d'Isard, connectada a la intranet per `itb 6` | Assumit |
| T19 | Els clients no veuen els contenidors: un pont i `ipvlan` ja han fallat (filtre de MAC d'Isard i trànsit que no passa pel router) | Mitjana | Alt | Els clients arriben per enrutament a través de l'equip dels serveis, amb la intranet com a pont normal | Verificat (20/11/2026); vegeu doc [04](04-clients-isard.md) |
| T20 | Pèrdua de configuració o de dades del servidor | Baixa | Alt | Tota la configuració és a GitHub i les dades de MySQL van a un volum Docker; la infraestructura es recrea amb `docker compose up -d --build` | Definit; la restauració de la BBDD no s'ha provat ([pla de proves](15-criteris-rendiment-disponibilitat.md#7-pla-de-proves), C4) |
| T21 | Barreja de *backends* iptables i nftables a la mateixa màquina | Baixa | Mitjà | Mantenir iptables al router i no activar el *backend* nftables experimental de Docker ([estudi previ 11](11-estudi-previ-web-monitor-firewall.md), apartat 4) | Definit |
| T22 | Una actualització de MySQL a la 8.4 desactiva `mysql_native_password` | Baixa | Mitjà | Fixar MySQL 8.0 i revisar els usuaris abans d'actualitzar ([estudi previ 09](09-estudi-previ.md), apartat 9.3) | Definit |
| T23 | Conflictes de Git entre els dos integrants | Mitjana | Baix | Una branca de vida curta per cada tasca de ProofHub i Pull Request cap a `main` ([control de versions](14-control-versions.md)) | Aplicat (PR #3 a #11) |
| T24 | El `vsftpd` d'Ubuntu 22.04 es tanca (codi 139) amb connexions seguides; Docker el reinicia (més de 250 reinicis en uns 3 dies) | Alta | Baix | `restart: unless-stopped` el recupera en pocs segons; `healthcheck` cada 30 s per tenir menys connexions; la causa no s'ha pogut arreglar per configuració | Documentat; vegeu doc [24](24-servidor-ftp.md) |

Els riscos T2, T6, T7, T9, T13, T14, T15 i T24 són limitacions conegudes que no tenen mitigació automàtica; es mencionen a la defensa. Els riscos s'han de revisar al final de cada sprint i s'ha d'afegir qualsevol incidència nova.

## 7. Riscos laborals
El treball és de tipus ofimàtic davant de pantalla (equips de visualització de dades), sota la Llei 31/1995 de Prevenció de Riscos Laborals i el Reial decret 488/1997.

| # | Risc | Prob. | Impacte | Prevenció |
|---|---|---|---|---|
| L1 | Fatiga visual per hores seguides davant la pantalla | Alta | Baix | Pauses curtes periòdiques, distància i il·luminació adequades, ajustar brillantor i mida del text |
| L2 | Problemes musculoesquelètics per postura (esquena, coll, canells) | Mitjana | Mitjà | Cadira regulable, pantalla a l'alçada dels ulls, teclat i ratolí còmodes, alternar postura |
| L3 | Estrès i fatiga per l'acumulació de tasques i els terminis | Mitjana | Mitjà | Repartir les tasques entre els dos membres, planificar per sprints, respectar els descansos |
| L4 | Risc elèctric lleu per endolls i regletes sobrecarregats | Baixa | Mitjà | No sobrecarregar regletes; revisar cables en mal estat |
| L5 | Treball amb la configuració de l'aula o de l'equip aliè | Baixa | Baix | Treballar dins els contenidors i els equips assignats; no modificar l'equipament d'altri |

Les mesures dels riscos laborals són recomanacions generals; no hi ha evidència al repositori que s'hagin aplicat, i per això no s'indica cap estat de verificació.

## 8. Seguiment
- **ProofHub:** cada tasca té responsable, data de venciment i criteri de «feta»; s'hi registren les hores treballades.
- **Diari de treball:** es porta a ProofHub, amb un comentari a cada tasca de cada sessió (què s'ha fet i què falla) i les hores treballades.
- **GitHub:** cada tasca de ProofHub té la seva branca i el seu Pull Request, i cada commit recull una sola part del treball.
- **Etiquetes:** el tancament de cada sprint es marca amb una etiqueta de Git (`sprint1`, `sprint2`...).

## 9. Historial de versions
| Versió | Data | Canvis |
|---|---|---|
| 1.0 | 15/11/2026 | Primera versió: fases, tasques, recursos, dedicació, riscos i seguiment |
| 1.1 | 16/11/2026 | Una branca per tasca de ProofHub en lloc d'una per persona |
| 1.2 | 17/11/2026 | Els clients passen a ser màquines virtuals a Isard (itb 6) i nou risc del filtre de MAC |
| 1.3 | 18/11/2026 | Els clients arriben a la intranet per enrutament; riscos actualitzats |
| 1.4 | 23/11/2026 | S'hi integra la prevenció de riscos (abans en un document a part): una sola taula de riscos tècnics i els riscos laborals; el diari de treball passa a ProofHub |
| 1.5 | 25/11/2026 | Nou risc T24: tancaments de `vsftpd` (codi 139) |
