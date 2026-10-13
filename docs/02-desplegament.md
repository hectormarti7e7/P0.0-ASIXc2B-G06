# 2. Manual de desplegament (client)

## Requisits
- Linux (o Windows amb WSL2 / Docker Desktop) amb Docker Engine 24+ i Docker Compose v2.
- Accés a Internet (baixar imatges i el CSV d'Open Data BCN).
- Ports lliures al host: 80, 443, 21, 2222, 3001, 30000-30009 (es poden canviar a `.env`).

## Desplegar
```bash
git clone git@github.com:<usuari>/P0.0-ASIXc2gC-Gnn.git
cd P0.0-ASIXc2gC-Gnn
./deploy.sh up          # construeix, arrenca, carrega el CSV i executa les proves
```
El primer cop triga uns minuts (descàrrega d'imatges i paquets).

## Comandes
| Comanda | Efecte |
|---|---|
| `./deploy.sh up` | Desplega tot |
| `./deploy.sh test` | Torna a passar el joc de proves |
| `./deploy.sh status` | Estat dels contenidors |
| `./deploy.sh logs web` | Logs d'un servei |
| `./deploy.sh down` | Atura (conserva dades) |
| `./deploy.sh reset` | Atura i esborra volums (BBDD, FTP, monitor) |

## Accessos (usuari **bchecker** / **bchecker121** a tot)
| Servei | Accés |
|---|---|
| Web | http://localhost  i  https://localhost (cert. autosignat) |
| SSH | `ssh -p 2222 bchecker@localhost` (bastió S-NCC) |
| Entrar a qualsevol equip | `docker exec -it W-N01 bash` o `ssh bchecker@W-N01` des del client |
| MySQL | des del client: `mysql -h B-N01 -ubchecker -pbchecker121 equipaments` |
| FTP | `ftp localhost` (si és remot: posar `PUBLIC_IP` a `.env`) |
| Monitor | http://localhost:3001 — la primera vegada crea l'administrador **bchecker / bchecker121** |

## Client Windows
Docker no pot executar un Windows "normal" com a contenidor Linux. Opcions:
1. **Perfil experimental** `docker compose --profile windows up -d pc-windows` (necessita `/dev/kvm`; visor a http://localhost:8006). No agafa IP del nostre DHCP (el contenidor porta el seu propi NAT intern).
2. **Màquina virtual** (VirtualBox/VMware) amb adaptador *bridge* a la xarxa del host; és l'opció recomanada per a la demostració de DHCP amb Windows.

## Si no hi ha Internet
Copia el CSV a `data/equipaments.csv`; el *loader* el farà servir automàticament.
