# 5. Control de versions (Git / GitHub)

Repositori: `P0.0-ASIXc2gC-Gnn` (g = grup A/B, nn = número de grup).

## Autenticació per clau pública/privada
```bash
ssh-keygen -t ed25519 -C "servidor-P0.0" -f ~/.ssh/id_ed25519_p00
cat ~/.ssh/id_ed25519_p00.pub          # afegir-la a GitHub > Settings > SSH keys (o Deploy keys amb write)
cat >> ~/.ssh/config <<'CFG'
Host github.com
  IdentityFile ~/.ssh/id_ed25519_p00
CFG
ssh -T git@github.com                  # comprova l'autenticació
```

## Primera pujada
```bash
git init -b main
git add .
git commit -m "P0.0: infraestructura Docker inicial"
git remote add origin git@github.com:<usuari>/P0.0-ASIXc2gC-Gnn.git
git push -u origin main
```

## Cicle de treball
| Ordre | Ús |
|---|---|
| `git clone <url>` | Baixar el projecte (al servidor de producció) |
| `git add <fitxer>` | Preparar canvis |
| `git commit -m "missatge"` | Desar canvis |
| `git push` | Pujar a GitHub |
| `git pull` | Baixar canvis del company |

## Pujada a producció
1. Treball en branca: `git checkout -b feature/xxx` → `commit` → `push`.
2. Pull request i revisió pel company.
3. Fusió a `main`.
4. Al servidor: `git pull && ./deploy.sh up` (redesplega només el que ha canviat).

El fitxer `.env` no es puja (`.gitignore`); `.env.example` sí.
