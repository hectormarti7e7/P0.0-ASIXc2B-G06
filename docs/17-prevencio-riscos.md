# 17. Prevenció de riscos tècnics i laborals

Versió 1.0 · Projecte P0.0 «Desplegament d'infraestructura» · Equip G06 (N06)

Aquest document recull els riscos que hem trobat durant el projecte i els que
afecten el lloc de treball. La probabilitat i l'impacte són valoracions
qualitatives de l'equip (Baixa, Mitjana, Alta); no provenen de cap mesura.
L'estat només és «Verificat» quan hi ha una prova al repositori.

## 1. Riscos tècnics

| # | Risc | Prob. | Impacte | Prevenció o mitigació | Estat |
|---|---|---|---|---|---|
| T1 | Docker 28 descarta paquets de xarxes a l'host (regles *raw*) i el tràfic dels clients no arriba a la intranet | Alta | Alt | Script `scripts/xarxa-clients.sh` que afegeix regles a `DOCKER-USER` | Configurat; vegeu docs 01 i 04 |
| T2 | Les regles `iptables` de l'script de xarxa no persisteixen després d'un reinici de l'host | Alta | Mitjà | Tornar a executar `sudo ./scripts/xarxa-clients.sh` després de cada reinici | Limitació documentada; no automatitzat |
| T3 | Un fitxer de muntatge (*bind mount*) inexistent es crea com a directori propietat de `root` i el servei no arrenca | Mitjana | Mitjà | Comprovar que els fitxers existeixen abans de `docker compose up`; eliminar-los amb `sudo rmdir` | Verificat (trobat i corregit el 22/11/2026) |
| T4 | Editar un fitxer muntat no reinicia el contenidor i el canvi no s'aplica | Mitjana | Baix | `docker compose up -d --force-recreate <servei>` | Verificat |
| T5 | El port publicat del router arriba per la pota DMZ i la connexió SSH és refusada | Mitjana | Alt | `gw_priority: 1` a la xarxa `nat` i `MASQUERADE` cap a la DMZ | Verificat (22/11/2026) |
| T6 | FTP sense TLS: credencials i dades viatgen en clar | Alta | Mitjà | Limitació acceptada i documentada (vsftpd sortia sense missatge amb `ssl_enable=YES`); fer servir només dins la xarxa del projecte | Documentat; vegeu doc 24 |
| T7 | El DHCP no arriba als clients de `itb 6` (difusió) | Alta | Baix | Proves fetes en un contenidor de la intranet | Documentat; vegeu doc 25 |
| T8 | El fitxer CSV és UTF-16 amb 40 columnes i es carrega malament | Mitjana | Mitjà | Càrrega amb `load_csv.py`; verificació amb `--default-character-set=utf8mb4` | Verificat (2.709 files) |
| T9 | El *loader* fa `DROP TABLE IF EXISTS` i esborra dades en tornar a executar-lo | Mitjana | Alt | Còpia amb `mysqldump` abans de tornar a carregar | Documentat; vegeu doc 05 |
| T10 | La imatge d'Uptime Kuma 1.23.16 és Debian 10 (*buster*, fora de suport) i `apt` falla | Alta | Baix | Repositoris d'`archive.debian.org` al `Dockerfile` | Verificat |
| T11 | La web depèn de la base de dades: si `B-N06` cau, l'aplicació deixa de servir dades | Mitjana | Alt | Sonda de monitorització sobre MySQL i prova de caiguda i recuperació | Verificat (23/11/2026) |
| T12 | Tots els serveis depenen d'un únic host (punt únic de fallada) | Baixa | Alt | Cap; risc assumit per l'abast del projecte | Assumit |
| T13 | Credencials per defecte compartides (`bchecker`/`bchecker121` exigides per l'enunciat) i `bchecker` amb tots els privilegis a la BD | Alta | Alt | Accés SSH només per clau; contrasenya de l'aplicació configurable amb `APP_USER`/`APP_PASS` | Parcial; el compte és imposat |
| T14 | Certificats TLS autosignats: el navegador avisa i no hi ha validació d'identitat | Alta | Baix | Acceptat per a l'entorn de proves | Assumit |
| T15 | Uptime Kuma sense notificacions: una caiguda només es veu mirant el tauler | Mitjana | Mitjà | Revisió manual del tauler | Limitació documentada; vegeu doc 26 |

## 2. Riscos laborals

El treball és de tipus ofimàtic davant de pantalla (equips de visualització de
dades), sota la Llei 31/1995 de Prevenció de Riscos Laborals i el Reial decret
488/1997.

| # | Risc | Prob. | Impacte | Prevenció |
|---|---|---|---|---|
| L1 | Fatiga visual per hores seguides davant la pantalla | Alta | Baix | Pauses curtes periòdiques, distància i il·luminació adequades, ajustar brillantor i mida del text |
| L2 | Problemes musculoesquelètics per postura (esquena, coll, canells) | Mitjana | Mitjà | Cadira regulable, pantalla a l'alçada dels ulls, teclat i ratolí còmodes, alternar postura |
| L3 | Estrès i fatiga per l'acumulació de tasques i els terminis | Mitjana | Mitjà | Repartir les tasques entre els dos membres, planificar per sprints, respectar els descansos |
| L4 | Risc elèctric lleu per endolls i regletes sobrecarregats | Baixa | Mitjà | No sobrecarregar regletes; revisar cables en mal estat |
| L5 | Treball amb la configuració de l'aula o de l'equip aliè | Baixa | Baix | Treballar dins els contenidors i els equips assignats; no modificar l'equipament d'altri |

## 3. Seguiment

- Els riscos T1 a T15 s'han de revisar al final de cada sprint i s'ha d'afegir
  qualsevol incidència nova que es trobi.
- Els riscos T2, T6, T7, T9, T13, T14 i T15 són limitacions conegudes que no
  tenen mitigació automàtica; es mencionen a la defensa.
- Les mesures dels riscos laborals són recomanacions generals; no hi ha
  evidència al repositori que s'hagin aplicat, i per això no s'indica cap
  estat de verificació.
