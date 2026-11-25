# Servidor FTP (F-N06)

| | |
|---|---|
| **Projecte** | P0.0 · Desplegament d'infraestructura |
| **Mòdul** | 0379 · Projecte intermodular (ASIX) |
| **Equip** | G06 (ASIXc2B) · identificador N06 |
| **Autors** | Hèctor Martí, Josep Pérez |
| **Versió** | 1.1 · 25/11/2026 · Sprint 2 |

## Índex
1. [Objectiu i abast](#1-objectiu-i-abast)
2. [Característiques](#2-característiques)
3. [Instal·lació i configuració](#3-installació-i-configuració)
4. [Seguretat](#4-seguretat)
5. [Comprovacions](#5-comprovacions)
6. [Resolució de problemes](#6-resolució-de-problemes)
7. [Historial de versions](#7-historial-de-versions)

## 1. Objectiu i abast
Aquest document descriu el servidor FTP `F-N06`: un servei de transferència de fitxers a la DMZ, accessible des de fora pel port 21 i amb el mode passiu als ports 30000-30009.

## 2. Característiques
| Element | Valor |
|---|---|
| Contenidor | `F-N06`, imatge construïda sobre la imatge base amb `vsftpd` |
| Xarxa i adreça | DMZ · 10.213.1.11 (gateway: el router, 10.213.1.254) |
| Usuari | `bchecker` / `bchecker121` (l'usuari que exigeix l'enunciat). És l'únic que pot entrar |
| Carpeta | `/srv/ftp`, només lectura; es pot pujar a `/srv/ftp/pujades` |
| Ports | 21 (control) i 30000-30009 (dades en mode passiu) |
| Adreça anunciada | `192.168.50.22` (variable `FTP_PASV_ADDRESS`): l'adreça per on entra el client |

## 3. Instal·lació i configuració
S'arrenca amb tota la infraestructura (`docker compose up -d --build`).

| Fitxer | Contingut |
|---|---|
| `services/ftp/init.sh` | Crea les carpetes, la llista d'usuaris i `/etc/vsftpd.conf`; el registre surt per `docker logs` |
| `docker-compose.yml` | Servei `ftp`; el router publica el port 21 i el rang 30000-30009 |
| `services/router/init.sh` | Regla `FORWARD`, `DNAT` i `MASQUERADE` per al port 21 i el rang passiu cap a `F-N06` |

### 3.1 Opcions de `vsftpd` més importants
| Opció | Efecte |
|---|---|
| `anonymous_enable=NO` | No hi ha accés anònim |
| `userlist_enable=YES`, `userlist_deny=NO` | Només entren els usuaris de `/etc/vsftpd.userlist` (`bchecker`) |
| `local_root=/srv/ftp` i `chroot_local_user=YES` | L'usuari queda tancat a `/srv/ftp` i no veu la resta del sistema |
| `pasv_min_port` i `pasv_max_port` | Mode passiu als ports 30000-30009 |
| `pasv_address` | Adreça que s'anuncia al client en mode passiu (la de l'equip dels serveis, no la del contenidor) |

L'arrel `/srv/ftp` és de `root` i no es pot escriure: si fos escrivible per l'usuari, `vsftpd` no el tancaria (`chroot`). Per això es puja a la subcarpeta `pujades`.

### 3.2 Per què l'adreça passiva
En mode passiu, el servidor diu al client a quina adreça i port ha de connectar per a les dades. Si digués l'adreça del contenidor (10.213.1.11), el client no hi podria arribar. Per això `pasv_address` és l'adreça de l'equip dels serveis (`192.168.50.22` a Isard), on el router publica els ports 30000-30009. En un altre entorn es canvia amb la variable `FTP_PASV_ADDRESS` a `.env`.

## 4. Seguretat
| Mesura | Efecte |
|---|---|
| Sense accés anònim i amb llista d'usuaris | Només `bchecker` pot iniciar sessió |
| `chroot` | L'usuari no pot sortir de `/srv/ftp` |
| Arrel de només lectura | Només es pot escriure a `pujades` |
| Firewall del router | Només s'obre el 21 i el rang 30000-30009 cap a `F-N06`; la resta de la DMZ no és accessible des de fora |
| Registre | Cada ordre FTP queda a `docker logs F-N06` |

**Limitació: no hi ha xifratge.** FTP envia l'usuari i la contrasenya en text clar. S'ha provat d'activar TLS (`ssl_enable=YES`), però en aquesta imatge `vsftpd` es tancava sense missatge d'error en activar-lo, i no s'ha pogut resoldre en el temps disponible. Per això el servei funciona amb FTP normal. Per a una administració segura es recomana usar el servidor SSH ([document 07](07-servidor-ssh.md)); una millora futura és activar FTPS o substituir FTP per SFTP.

**Limitació: `vsftpd` es tanca de tant en tant (codi 139).** El `vsftpd` d'aquesta imatge (Ubuntu 22.04) acaba amb un *segmentation fault* quan rep connexions seguides. `dmesg` mostra `segfault at 0` sempre a la mateixa posició del programa, i Docker el torna a arrencar sol (`restart: unless-stopped`). El 25/11/2026 el comptador de reinicis (`docker inspect -f '{{.RestartCount}}' F-N06`) marcava més de 250 en uns 3 dies, aproximadament un cada 18 minuts. Entre la caiguda i la nova arrencada passen uns 0,2 a 0,5 s; després `vsftpd` triga uns segons a acceptar connexions.

Es va provar d'arreglar-ho en un contenidor apart, amb fins a 60 connexions seguides (una cada 0,5 s), i no es va aconseguir:

| Prova | Resultat |
|---|---|
| Configuració actual | Tancament (codi 139) |
| `seccomp_sandbox=YES` | Tancament |
| `isolate=NO` i `isolate_network=NO` | Tancament |
| `max_per_ip=0` i `max_clients=0` | Tancament |
| Sense `connect_from_port_20` | Tancament |
| Sense `chroot_local_user` ni `secure_chroot_dir` | Tancament |
| Sense les opcions `pasv_*` | Tancament |
| Sense el registre (`xferlog`, `vsftpd_log_file`, `log_ftp_protocol`) | Tancament |
| `one_process_model=YES` | Sobreviu, però el servidor respon `500 OOPS: security: 'one_process_model' is anonymous only` i no es pot fer servir amb `bchecker` |

També es va comprovar que no és només el patró de connectar i tancar sense dir res: unes connexions que llegien la salutació i enviaven `QUIT` (fins a 200, una cada 0,5 s) el van tancar a la 29. Per tant, la causa sembla un error del programa en aquest entorn, i no una opció de configuració; no s'ha investigat més.

**Mitigació.** El `healthcheck` del contenidor feia una connexió cada 5 s i ara en fa una cada 30 s (`docker-compose.yml`), de manera que n'hi ha menys. La sonda del monitor ([document 26](26-monitoritzacio.md)) continua fent una connexió cada 20 s. S'espera que els tancaments siguin menys freqüents; no s'ha mesurat encara. Si en una versió futura es vol eliminar el problema, l'alternativa és substituir `vsftpd` per un altre servidor FTP, com `proftpd`.

## 5. Comprovacions
Es fan des del client Linux (`PC-L-N06`) contra l'equip dels serveis (`192.168.50.22`), el 22/11/2026. S'usa `curl` amb `--user bchecker:bchecker121`.

| # | Prova | Ordre | Esperat | Obtingut |
|---|---|---|---|---|
| 1 | Llistar | `curl ftp://192.168.50.22/` | Mostra `benvinguda.txt` i `pujades` | Correcte |
| 2 | Descarregar | `curl ftp://192.168.50.22/benvinguda.txt` | Mostra el contingut | `Servidor FTP de la practica P0.0 (equip N06)` |
| 3 | Pujar a `pujades` | `curl -T prova.txt ftp://192.168.50.22/pujades/` | Permès | Pujada correcta i apareix `prova.txt` |
| 4 | Pujar a l'arrel | `curl -T prova.txt ftp://192.168.50.22/` | Denegat | Codi 25 (denegat) |
| 5 | Contrasenya incorrecta | `curl --user bchecker:mal ftp://192.168.50.22/` | Denegat | Codi 67 (inici de sessió rebutjat) |
| 6 | Usuari `root` | `curl --user root:root ftp://192.168.50.22/` | Denegat | Codi 67 |
| 7 | Sortir de la carpeta | `curl ftp://192.168.50.22/../etc/passwd` | No es pot veure | Codi 9 (accés denegat) |

Les proves 1 a 3 utilitzen el mode passiu pels ports 30000-30009: si el rang no estigués obert, el llistat fallaria.

## 6. Resolució de problemes
| Símptoma | Causa | Solució |
|---|---|---|
| El llistat es queda penjat o falla, però el login funciona | El mode passiu no arriba al client | Comprovar `FTP_PASV_ADDRESS` (ha de ser l'adreça per on entra el client) i que el router publica 30000-30009 (`docker compose ps`) |
| El contenidor es reinicia sense missatge | `vsftpd` es tanca per una opció que no accepta (a la prova, `ssl_enable=YES`) | Trobar-la treient opcions de `/etc/vsftpd.conf` d'una en una |
| `500 OOPS: vsftpd: refusing to run with writable root inside chroot()` | L'arrel de `/srv/ftp` és escrivible | `chmod 755` i propietari `root` a `/srv/ftp` |
| `Connection refused` al port 21 | El servei no s'ha arrencat o el router no ha publicat el port | `docker compose ps` i `docker logs F-N06` |
| El contenidor es reinicia i `dmesg` mostra `vsftpd ... segfault` | Fallada coneguda de `vsftpd` amb connexions seguides (apartat 4) | Es recupera sol; el recompte és a `docker inspect -f '{{.RestartCount}}' F-N06` |

## 7. Historial de versions
| Versió | Data | Canvis |
|---|---|---|
| 1.0 | 22/11/2026 | Primera versió: vsftpd, mode passiu, regles del router i proves |
| 1.1 | 25/11/2026 | Limitació documentada: `vsftpd` es tanca (codi 139) amb connexions seguides; `healthcheck` cada 30 s |
