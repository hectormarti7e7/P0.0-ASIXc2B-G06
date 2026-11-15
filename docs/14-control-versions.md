# Control de versions amb Git i GitHub

| | |
|---|---|
| **Projecte** | P0.0 · Desplegament d'infraestructura |
| **Mòdul** | 0379 · Projecte intermodular (ASIX) |
| **Equip** | G06 (ASIXc2B) · identificador N06 |
| **Autor** | Josep Pérez |
| **Versió** | 1.0 · 15/11/2026 · Sprint 1 |

## Índex
1. [Objectiu i abast](#1-objectiu-i-abast)
2. [Repositori](#2-repositori)
3. [Autenticació amb clau pública i privada](#3-autenticació-amb-clau-pública-i-privada)
4. [Comandes bàsiques](#4-comandes-bàsiques)
5. [Flux de treball amb branques](#5-flux-de-treball-amb-branques)
6. [Pujada a producció](#6-pujada-a-producció)
7. [Missatges de commit](#7-missatges-de-commit)
8. [Resolució de problemes](#8-resolució-de-problemes)
9. [Historial de versions](#9-historial-de-versions)

## 1. Objectiu i abast
Aquest document explica com treballem amb Git i GitHub: com s'accedeix al repositori amb clau pública i privada, quines comandes s'usen (`git clone`, `add`, `commit -m`, `push` i `pull`), com s'organitzen les branques i com es puja un canvi a producció.

## 2. Repositori
| Element | Valor |
|---|---|
| Nom | `P0.0-ASIXc2B-G06` (format `P0.0-ASIXc2gC-Gnn`: grup B, equip 06) |
| URL (SSH) | `git@github.com:hectormarti7e7/P0.0-ASIXc2B-G06.git` |
| Branca principal | `main`: estat estable i lliurable. Els canvis hi arriben per Pull Request |
| Col·laboradors | Josep Pérez i Hèctor Martí |

Tota la configuració i la documentació del projecte són en aquest repositori.

## 3. Autenticació amb clau pública i privada
El servidor i cada equip de treball s'autentiquen a GitHub amb un parell de claus SSH, sense contrasenya: la clau **privada** es queda a la màquina i la clau **pública** es registra a GitHub. La clau privada no es copia ni es puja mai al repositori.

### 3.1 Generar la clau
```bash
ssh-keygen -t ed25519 -C "equip G06 N06"
cat ~/.ssh/id_ed25519.pub
```
La primera ordre crea `~/.ssh/id_ed25519` (privada) i `~/.ssh/id_ed25519.pub` (pública). La segona mostra la clau pública, que és el que cal copiar.

### 3.2 Registrar la clau pública a GitHub
- **Clau d'usuari** (per treballar amb el repositori): GitHub, *Settings*, *SSH and GPG keys*, *New SSH key*, i enganxar el contingut del fitxer `.pub`.
- **Clau de desplegament** (per a un servidor que només ha de baixar el codi): repositori, *Settings*, *Deploy keys*, *Add deploy key*. És de només lectura, suficient per a `git clone` i `git pull`. Només es marca *Allow write access* si el servidor ha de pujar canvis.

### 3.3 Comprovar l'accés
```bash
ssh -T git@github.com
```
Resultat esperat: un missatge que indica que l'autenticació ha anat bé (`Hi <usuari>! You've successfully authenticated, but GitHub does not provide shell access.`). La primera vegada demana confirmar l'empremta del servidor; cal respondre `yes` només si coincideix amb les empremtes que publica GitHub.

### 3.4 Identitat de Git
Cada integrant configura el seu nom i correu perquè els commits quedin ben atribuïts:
```bash
git config --global user.name "Nom Cognom"
git config --global user.email "correu@exemple.cat"
git config --global --list
```

## 4. Comandes bàsiques
| Comanda | Què fa |
|---|---|
| `git clone <url>` | Descarrega el repositori i el seu historial |
| `git status` | Mostra els fitxers modificats i els que estan preparats per al commit |
| `git add <fitxer>` | Prepara un fitxer per al proper commit |
| `git commit -m "missatge"` | Desa els canvis preparats amb un missatge |
| `git push` | Puja els commits locals a GitHub (la primera vegada d'una branca, `git push -u origin <branca>`) |
| `git pull` | Baixa els canvis de GitHub i els integra a la branca actual |
| `git switch <branca>` | Canvia de branca |
| `git switch -c <branca>` | Crea una branca nova i hi canvia |
| `git log --oneline` | Mostra l'historial de commits resumit |
| `git diff` | Mostra els canvis que encara no estan preparats |

### 4.1 Cicle de treball habitual
```bash
git clone git@github.com:hectormarti7e7/P0.0-ASIXc2B-G06.git    # només la primera vegada
cd P0.0-ASIXc2B-G06
git switch main
git pull
git switch -c <branca>
# ...es modifiquen fitxers...
git status
git add <fitxer>
git commit -m "docs: descripció del canvi"
git push -u origin <branca>
```

## 5. Flux de treball amb branques
- No es treballa directament a `main`.
- Cada integrant treballa en una branca amb el nom `sprintN/nom`, per exemple `sprint1/josep` o `sprint1/hector`. Per a feines concretes es pot usar un prefix com `chore/`.
- Per integrar els canvis s'obre un **Pull Request** cap a `main` amb la [plantilla del repositori](../.github/pull_request_template.md). L'altre integrant el revisa i, un cop aprovat, es fusiona.
- Després de la fusió, cadascú actualitza el seu `main` local amb `git pull`.
- Les branques antigues no s'esborren: es conserven amb el prefix `archiu/` (per exemple `archiu/sprint1-josep-vell`).
- El tancament d'un sprint es marca amb una etiqueta:

```bash
git tag -a sprintN -m "Tancament del sprint N"
git push origin sprintN
```

## 6. Pujada a producció
«Producció» és el servidor on es desplega la infraestructura. Només s'hi desplega el que és a `main`, que ja ha estat revisat.

```bash
cd P0.0-ASIXc2B-G06
git switch main
git pull
docker compose up -d --build
docker compose ps
```

El fitxer `.env` es crea al servidor a partir de `.env.example` i no es puja al repositori (és al `.gitignore`).

Si un canvi desplegat falla, es desfà amb un nou commit mitjançant `git revert <commit>` (que també passa per Pull Request) i es torna a desplegar amb les mateixes comandes.

## 7. Missatges de commit
El format és `tipus(àmbit): descripció`. L'àmbit és opcional.

| Tipus | Quan s'usa |
|---|---|
| `feat` | Servei o funcionalitat nova |
| `fix` | Correcció d'un error |
| `docs` | Documentació |
| `chore` | Estructura, configuració o manteniment |

Exemples reals del repositori:
- `docs(arquitectura): diagrama de la infraestructura (N06)`
- `chore: estructura de carpetes comuna i .gitignore`

Cada commit recull una sola part lògica del canvi, de manera que l'historial es pot llegir i revisar per parts.

## 8. Resolució de problemes
| Símptoma | Causa probable | Solució |
|---|---|---|
| `Permission denied (publickey)` | La clau pública no és a GitHub o el remot no és SSH | `ssh -T git@github.com` i `git remote -v` (ha de ser `git@github.com:...`) |
| `GH006: Protected branch update failed` | S'ha intentat pujar directament a `main` | Crear una branca i obrir un Pull Request |
| `rejected ... (non-fast-forward)` | Hi ha commits nous a GitHub que no tens en local | `git pull` i tornar a fer `git push` |
| `CONFLICT` en fer `git pull` o fusionar | Dos canvis toquen les mateixes línies | Editar el fitxer (marques `<<<<<<<`, `=======` i `>>>>>>>`), `git add <fitxer>` i `git commit` |
| `Your local changes would be overwritten` | Hi ha canvis sense desar en canviar de branca o fer `git pull` | Fer-hi `git commit` o desar-los amb `git stash` |
| `fatal: not a git repository` | La comanda no s'ha executat dins de la carpeta del repositori | Entrar a la carpeta del projecte amb `cd` |

## 9. Historial de versions
| Versió | Data | Canvis |
|---|---|---|
| 1.0 | 15/11/2026 | Primera versió: clau SSH, comandes, flux de branques, pujada a producció i resolució de problemes |
