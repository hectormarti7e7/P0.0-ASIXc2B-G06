#!/usr/bin/env bash
# Desplegament automatitzat de tota la infraestructura P0.0
# Ús: ./deploy.sh [up|down|reset|test|status|logs]
set -euo pipefail
cd "$(dirname "$0")"

cmd="${1:-up}"
command -v docker >/dev/null || { echo "Docker no està instal·lat"; exit 1; }
docker compose version >/dev/null 2>&1 || { echo "Cal Docker Compose v2"; exit 1; }
[ -f .env ] || { cp .env.example .env; echo "[deploy] creat .env des de .env.example"; }
set -a; . ./.env; set +a
NCC="${NCC:-N01}"

case "$cmd" in
  up)
    docker compose build
    docker compose up -d
    echo "[deploy] esperant la càrrega del CSV..."
    docker wait "LOADER-${NCC}" >/dev/null 2>&1 || true
    docker logs "LOADER-${NCC}" 2>&1 | tail -3
    ./tests/check.sh || echo "[deploy] alguna prova ha fallat (vegeu dalt)"
    echo
    echo "Web:      http://localhost:${HTTP_PORT:-80}   (bchecker / bchecker121)"
    echo "Monitor:  http://localhost:${MONITOR_PORT:-3001}"
    echo "SSH:      ssh -p ${SSH_PORT:-2222} bchecker@localhost"
    ;;
  down)   docker compose down ;;
  reset)  docker compose down -v ;;
  test)   ./tests/check.sh ;;
  status) docker compose ps ;;
  logs)   docker compose logs -f --tail=50 "${2:-}" ;;
  *) echo "Ús: $0 [up|down|reset|test|status|logs]"; exit 1 ;;
esac
