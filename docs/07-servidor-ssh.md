# Servidor SSH (S-N06)

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
3. [Instal·lació](#3-installació)
4. [Configuració](#4-configuració)
5. [Seguretat](#5-seguretat)
6. [Comprovacions](#6-comprovacions)
7. [Resolució de problemes](#7-resolució-de-problemes)
8. [Historial de versions](#8-historial-de-versions)

## 1. Objectiu i abast
Aquest document descriu el servidor SSH `S-N06`: com s'instal·la, com es configura, quines mesures de seguretat aplica i com es comprova que només deixa entrar amb clau pública. És el bastió d'administració de la infraestructura i és a la DMZ.

## 2. Característiques
| Element | Valor |
|---|---|
| Contenidor | `S-N06`, construït sobre la imatge base (que ja porta `openssh-server`) |
| Xarxa i adreça | DMZ · 10.213.1.12 (gateway: el router, 10.213.1.254) |
| Port | **2222** (TCP), el mateix a tot el camí |
| Usuari | `bchecker` (l'usuari que exigeix l'enunciat de la pràctica) |
| Autenticació | Només per **clau pública**; la contrasenya està desactivada |
| Accés des de fora | Port 2222 de l'equip dels serveis → router → `S-N06:2222` |

## 3. Instal·lació
No cal instal·lar res a mà. La imatge base (`images/base`) instal·la `openssh-server` i crea l'usuari `bchecker`. El servei s'arrenca amb tota la infraestructura:

```bash
docker compose up -d --build
docker compose ps          # S-N06 ha de sortir com a «healthy»
```

El `healthcheck` del servei comprova que el procés `sshd` està en marxa.

## 4. Configuració
| Fitxer | Contingut |
|---|---|
| `services/ssh/init.sh` | L'executa l'entrypoint a cada arrencada: escriu la configuració d'`sshd`, instal·la la clau autoritzada i valida la configuració amb `sshd -t`. Si falla, el contenidor no arrenca |
| `services/ssh/authorized_keys` | Clau pública autoritzada per a `bchecker` (la del client Linux, `bchecker@PC-L-N06`). Una clau pública no és secreta |
| `docker-compose.yml` | Servei `ssh`: adreça a la DMZ, gateway pel router, fitxers muntats en només lectura i `healthcheck` |
| `services/router/init.sh` | Regles del router per al port 2222 (vegeu l'apartat 4.2) |

### 4.1 Configuració d'sshd
`init.sh` escriu `/etc/ssh/sshd_config.d/10-p00.conf` amb:

```
Port 2222
PermitRootLogin no
AllowUsers bchecker
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitEmptyPasswords no
MaxAuthTries 3
LoginGraceTime 30
X11Forwarding no
LogLevel VERBOSE
```

La clau es copia a `/home/bchecker/.ssh/authorized_keys` amb el directori en mode 700, el fitxer en mode 600 i `bchecker` com a propietari. Si els permisos són més oberts, `sshd` ignora la clau (`StrictModes`).

### 4.2 Camí des de fora fins al servidor
1. El client es connecta al port 2222 de l'equip dels serveis (`192.168.50.22` des d'`itb 6`).
2. Docker reenvia el port 2222 al router (`10.213.3.2`, pota NAT). Per això el router porta `gw_priority: 1` a la xarxa `nat`: sense això Docker publicava el port per la pota de la DMZ i el trànsit no arribava a la regla del router.
3. El router fa un DNAT del port 2222 cap a `10.213.1.12:2222` i una regla `FORWARD` només deixa passar aquest port i aquest destí.
4. El router emmascara el trànsit cap a la DMZ perquè `S-N06` respongui sempre al router (si no, la resposta tornaria per una altra interfície).

Regles afegides a `services/router/init.sh`:
```
iptables -A FORWARD -i "$IF_NAT" -o "$IF_DMZ" -p tcp -d 10.213.1.12 --dport 2222 -j ACCEPT
iptables -t nat -A PREROUTING -i "$IF_NAT" -p tcp --dport 2222 -j DNAT --to-destination 10.213.1.12:2222
iptables -t nat -A POSTROUTING -o "$IF_DMZ" -p tcp -d 10.213.1.12 --dport 2222 -j MASQUERADE
```

## 5. Seguretat
| Mesura | Efecte |
|---|---|
| `PasswordAuthentication no` i `KbdInteractiveAuthentication no` | No s'accepta cap contrasenya: no es pot fer força bruta |
| `PermitRootLogin no` | `root` no pot entrar mai |
| `AllowUsers bchecker` | Només aquest usuari és vàlid |
| `MaxAuthTries 3` i `LoginGraceTime 30` | Limiten els intents i el temps per autenticar-se |
| Port 2222 | Evita els escàners automàtics del port 22 (no substitueix les altres mesures) |
| Firewall del router | Només s'obre el TCP 2222 cap a `S-N06`; la resta de la DMZ no és accessible des de fora |
| Permisos de `.ssh` | 700 al directori i 600 a `authorized_keys`, amb `bchecker` com a propietari |

**Nota sobre la contrasenya de `bchecker`:** l'enunciat obliga que l'usuari `bchecker` existeixi amb la contrasenya `bchecker121` a tots els sistemes, per això el compte la té. Per SSH no serveix de res: el servidor no accepta contrasenyes, només la clau.

## 6. Comprovacions
Es fan des del client Linux (`PC-L-N06`, `192.168.50.50`) contra l'equip dels serveis (`192.168.50.22`). Abans s'ha generat la clau, sense contrasenya perquè la prova es pugui repetir sense intervenció:

```bash
ssh-keygen -t ed25519 -C "bchecker@PC-L-N06" -f ~/.ssh/id_ed25519_bchecker -N ""
cat ~/.ssh/id_ed25519_bchecker.pub     # aquesta és la línia de services/ssh/authorized_keys
```

### 6.1 Configuració efectiva del servidor
```bash
docker exec S-N06 sshd -T | grep -Ei '^(port|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication|permitrootlogin|allowusers)'
```
Resultat obtingut (22/11/2026):
```
port 2222
permitrootlogin no
pubkeyauthentication yes
passwordauthentication no
kbdinteractiveauthentication no
allowusers bchecker
```

### 6.2 Accés autoritzat i accessos denegats
| # | Prova | Ordre | Resultat esperat | Resultat obtingut |
|---|---|---|---|---|
| 1 | Accés amb la clau autoritzada | `ssh -p 2222 -i ~/.ssh/id_ed25519_bchecker -o IdentitiesOnly=yes bchecker@192.168.50.22 'hostname; whoami'` | Entra i mostra el nom i l'usuari | Mostra `S-N06` i `bchecker`: **correcte** |
| 2 | Sense clau, forçant la contrasenya | `ssh -p 2222 -o PubkeyAuthentication=no -o PreferredAuthentications=password bchecker@192.168.50.22 'echo NO DEBERIA ENTRAR'` | Denegat | `Permission denied (publickey).`: **correcte** |
| 3 | `root` amb la clau autoritzada | `ssh -p 2222 -i ~/.ssh/id_ed25519_bchecker -o IdentitiesOnly=yes root@192.168.50.22 'echo NO'` | Denegat | `Permission denied (publickey).`: **correcte** |

A la prova 2, el servidor només ofereix `publickey`: no ofereix la contrasenya com a mètode, així que ni tan sols la demana. Això demostra que la contrasenya `bchecker121` no serveix per entrar per SSH.

## 7. Resolució de problemes
| Símptoma | Causa | Solució |
|---|---|---|
| `Connection refused` al port 2222 amb tot el sistema aixecat | El router no s'ha recreat amb el port publicat o Docker l'ha publicat per la pota de la DMZ | `docker compose up -d --force-recreate router ssh` i comprovar que `sudo iptables -t nat -S DOCKER \| grep 2222` apunta a `10.213.3.2` |
| El contenidor `S-N06` no arrenca (`falta /opt/authorized_keys`) | No existeix `services/ssh/authorized_keys` | Crear-lo amb la clau pública. Si no existeix, Docker crea un **directori** buit amb aquest nom: cal esborrar-lo amb `sudo rmdir` |
| `Permission denied (publickey)` amb la clau correcta | La clau del client no és la de `authorized_keys`, o els permisos de `.ssh` són massa oberts | Comparar la clau pública i comprovar que `/home/bchecker/.ssh` és 700 i `authorized_keys` és 600 |
| `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED` | Les claus d'host d'`sshd` pertanyen a la imatge i canvien si es reconstrueix (`--build` des de zero) | `ssh-keygen -R '[192.168.50.22]:2222'` al client |

## 8. Historial de versions
| Versió | Data | Canvis |
|---|---|---|
| 1.0 | 22/11/2026 | Primera versió: instal·lació, configuració, seguretat i proves |
