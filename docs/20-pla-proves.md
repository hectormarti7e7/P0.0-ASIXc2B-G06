# 20. Pla de proves

Versió 1.0 · Projecte P0.0 «Desplegament d'infraestructura» · Equip G06 (N06)

Aquest pla descriu les proves que cal fer sobre la infraestructura. La columna
«Resultat» només s'omple amb el que s'ha executat de veritat; la resta queda
com a **Pendent**. Els resultats ja obtinguts són als documents de cada servei i el resum, al document 22.

Convencions: `W-N06` web, `F-N06` FTP, `S-N06` SSH, `B-N06` base de dades,
`DNS-N06`, `DHCP-N06`, `MON-N06` monitor, `R-N06` router. IP: W 10.213.1.10,
F 10.213.1.11, S 10.213.1.12, B 10.213.2.10, MON 10.213.2.20, DNS 10.213.2.53,
DHCP 10.213.2.67, router 10.213.2.254.

## 1. Proves funcionals

| ID | Prova | Ordre o acció | Resultat esperat | Resultat |
|---|---|---|---|---|
| F1 | Contenidors en marxa | `docker compose ps` | Tots els serveis en estat `running` o `healthy` | Verificat (doc 22) |
| F2 | Dades carregades | `SELECT COUNT(*)` a la taula carregada | 2.709 files | Verificat (doc 05) |
| F3 | Web per HTTPS amb credencials | `curl -k -u usuari:contrasenya https://<host>/` | `200` | Verificat (doc 06) |
| F4 | Redirecció HTTP a HTTPS | `curl -I http://<host>/` | `301` | Verificat (doc 06) |
| F5 | Llistat FTP | Connexió a `F-N06` pel port 21 | Llistat del directori | Verificat (doc 24) |
| F6 | Resolució DNS del router | `dig @10.213.2.53 r-n06.asix.local` | `10.213.2.254` | Verificat (doc 08) |
| F7 | Concessió DHCP | `nmap --script broadcast-dhcp-discover` i `udhcpc` | Cicle DISCOVER, OFFER, REQUEST, ACK | Verificat (doc 25) |
| F8 | Client Linux arriba als serveis | Ping i SSH des de `PC-L-N06` | Respostes correctes | Verificat (docs 04 i 07) |
| F9 | Client Windows arriba als serveis | Pings a 192.168.50.22, 10.213.2.1, 10.213.2.254 i 10.213.2.10 | Respostes correctes | **Pendent** (Hèctor Martí) |

## 2. Proves de seguretat

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

## 3. Proves de contingència

| ID | Prova | Procediment | Resultat esperat | Resultat |
|---|---|---|---|---|
| C1 | Caiguda de la BD | `docker stop B-N06` i observar el tauler | La sonda MySQL passa a caiguda | Verificat el 23/11/2026 (doc 26) |
| C2 | Recuperació de la BD | `docker start B-N06` | La sonda torna a estar activa | Verificat el 23/11/2026 (doc 26) |
| C3 | Recreació d'un servei | `docker compose up -d --force-recreate <servei>` | El servei torna a estar actiu | Verificat amb `dns` |
| C4 | Còpia i restauració de la BD | `mysqldump` i restauració | Les files tornen a ser 2.709 | **Pendent**: la còpia es descriu al doc 05 però no s'ha provat la restauració |
| C5 | Reinici de l'host | Reiniciar i tornar a executar `xarxa-clients.sh` | Els clients tornen a tenir accés | **Pendent** |

## 4. Proves de monitorització

| ID | Prova | Resultat esperat | Resultat |
|---|---|---|---|
| M1 | Sonda web | Activa | Verificat (doc 26) |
| M2 | Sonda FTP | Activa | Verificat (doc 26) |
| M3 | Sonda SSH | Activa | Verificat (doc 26) |
| M4 | Sonda MySQL | Activa | Verificat (doc 26) |
| M5 | Sonda DNS | Activa | Verificat (doc 26) |
| M6 | Estat des de l'script | `estat_sondes.py` mostra les cinc sondes | Verificat (doc 26) |

## 5. Proves d'automatització

L'script `scripts/comprova.sh` executa part de les proves anteriors i mostra
`PASS` o `FAIL` per a cadascuna. Cobreix F1, F3, F4, F6, S2 i S5, entre
d'altres.

| ID | Prova | Resultat |
|---|---|---|
| A1 | Executar `./scripts/comprova.sh` a l'host | **Pendent** d'executar i anotar la sortida |

## 6. Proves de rendiment

Només s'ha mesurat el temps de càrrega del CSV: 1,019 s per a 2.709 files
(doc 05). No s'ha fet cap altra prova de rendiment i no s'inventen xifres.
Les proves de rendiment d'altres parts, si n'hi ha, es troben al document 15.

## 7. Com s'anota un resultat

1. Executar la prova i copiar la sortida real.
2. Afegir-la al document del servei corresponent amb la data real i anotar-ho al document 22.
3. Canviar «Pendent» per «Verificat» només en aquest moment.
