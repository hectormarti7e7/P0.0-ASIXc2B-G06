# P0.0 · Desplegament d'infraestructura

Infraestructura multicapa per a una aplicació web, desplegada amb **Docker** i descrita amb els fitxers d'aquest repositori. Pràctica P0.0 del mòdul 0379 · Projecte intermodular (ASIX).

| | |
|---|---|
| **Equip** | G06 (ASIXc2B) · identificador `N06` |
| **Integrants** | Josep Pérez i Hèctor Martí |
| **Mòdul** | 0379 · Projecte intermodular d'administració de sistemes informàtics en xarxa |
| **Durada** | 6 setmanes (fins al 18/11/2026), en 3 sprints quinzenals |

## Què descriu el projecte
Un router (`R-N06`) connecta tres xarxes i fa de firewall:

| Xarxa | Subxarxa | Serveis |
|---|---|---|
| DMZ | 10.213.1.0/24 | Web, FTP i SSH |
| Intranet | 10.213.2.0/24 | BBDD MySQL, DNS, DHCP, monitor i clients (Linux i Windows) |
| NAT | 10.213.3.0/24 | Sortida a Internet |

Cada servei és un contenidor Docker; els dos clients (Linux i Windows) són màquines virtuals al laboratori d'Isard, a la xarxa `itb 6`, que arriben a la intranet a través de l'equip dels serveis. El diagrama, l'adreçament IP i la política del firewall són a l'[arquitectura](docs/01-arquitectura.md). Tots els equips tenen l'usuari `bchecker` (contrasenya `bchecker121`), tal com demana l'enunciat.

## Estat
| Sprint | Contingut | Estat |
|---|---|---|
| 1 | Imatge base, xarxes, router i firewall base, diagrama, estudis previs i documentació | Tancat |
| 2 | Serveis: BBDD, web, SSH, DHCP, DNS, FTP, monitor i clients | En curs |
| 3 | Integració, proves, documentació final i defensa | Pendent |

Ara mateix el `docker-compose.yml` desplega el **router** (`R-N06`) i la **base de dades** (`B-N06`); el client Linux (`PC-L-N06`) és una màquina virtual d'Isard. La resta de serveis tenen la carpeta reservada a `services/` i s'afegeixen al sprint 2. El detall és al [pla del projecte](docs/16-pla-projecte.md).

## Posada en marxa
Requisits: Linux amb Docker Engine 24 o superior, Docker Compose v2 i Git. El procediment complet és al [manual de desplegament](docs/02-desplegament-client.md).

```bash
git clone git@github.com:hectormarti7e7/P0.0-ASIXc2B-G06.git
cd P0.0-ASIXc2B-G06
cp .env.example .env
docker compose up -d --build
docker compose ps
```

Per als clients d'Isard (xarxa `itb 6`), després d'aixecar els contenidors s'executa `sudo ./scripts/xarxa-clients.sh` (vegeu [clients](docs/04-clients-isard.md)).

Comprovació ràpida, des del client Linux (màquina virtual d'Isard): arriba al router.

```bash
ping -c 2 10.213.2.254
```

Per aturar la infraestructura: `docker compose down`.

## Estructura del repositori
```
.
├── docker-compose.yml     xarxes, router i BBDD
├── .env.example           NCC=N06 (identificador de l'equip)
├── scripts/               xarxa-clients.sh: connexió dels clients d'Isard
├── images/base/           imatge base comuna (Dockerfile i entrypoint.sh)
├── services/              configuració de cada servei
│   ├── router/init.sh     reenviament, NAT i firewall
│   ├── db/                MySQL: init.sh i init.sql
│   └── dhcp, dns, ftp, monitor, ssh, web   (carpetes reservades per al sprint 2)
├── docs/                  documentació (vegeu l'índex)
├── tests/                 proves (sprints 2 i 3)
└── .github/               plantilla de Pull Request
```

## Documentació
L'[índex de la documentació](docs/README.md) llista tots els documents. Els més útils per començar:

- [Arquitectura](docs/01-arquitectura.md)
- [Manual de desplegament](docs/02-desplegament-client.md)
- [Base de dades MySQL](docs/03-bbdd-mysql.md)
- [Clients a Isard (itb 6)](docs/04-clients-isard.md)
- [Càrrega del CSV](docs/05-carrega-csv.md)
- [Router i firewall](docs/10-router-firewall.md)
- [Control de versions amb Git i GitHub](docs/14-control-versions.md)
- [Criteris de rendiment i disponibilitat](docs/15-criteris-rendiment-disponibilitat.md)
- [Pla del projecte](docs/16-pla-projecte.md)

## Com col·laborem
`main` és la branca estable i s'hi arriba per Pull Request. Cada tasca de ProofHub té la seva branca de vida curta (per exemple `sprint2/bbdd-mysql`). Les regles i les comandes són a la [guia de control de versions](docs/14-control-versions.md).
