# P0.0-ASIXc2gC-Gnn — Infraestructura multicapa amb Docker

Desplegament automàtic (router, DMZ, intranet, web, BBDD MySQL, DHCP, DNS, FTP, SSH i monitor) amb Docker Compose.

```bash
cp .env.example .env     # opcional: canviar NCC, ports...
./deploy.sh up           # tot en una comanda
```

Usuari a tots els sistemes: `bchecker` / `bchecker121`.

Documentació completa a [`docs/`](docs/README.md). Canvia `gnn` pel teu grup (p. ex. `P0.0-ASIXc2A-G03`) en renombrar el repositori.
