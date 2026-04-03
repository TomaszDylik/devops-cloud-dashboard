#!/usr/bin/env bash
# =============================================================================
# run_dev.sh – uruchamia backend w trybie deweloperskim z hot-reload
#
# Bind mount kodu z hosta (./backend) do kontenera.
# nodemon obserwuje zmiany w index.js i automatycznie restartuje proces.
# Nie wymaga docker build przy zmianie kodu.
# =============================================================================
set -euo pipefail

NETWORK="dashboard-net"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Usun stary kontener deweloperski jesli istnieje
docker rm -f backend-dev 2>/dev/null || true

# Upewnij sie ze siec istnieje (postgres i redis musza dzialac)
docker network create "${NETWORK}" 2>/dev/null || true

# Sprawdz czy postgres i redis dzialaja
if ! docker ps --format '{{.Names}}' | grep -q '^postgres$'; then
  echo "BLAD: Kontener postgres nie dziala. Uruchom najpierw ./start.sh" >&2
  exit 1
fi
if ! docker ps --format '{{.Names}}' | grep -q '^redis$'; then
  echo "BLAD: Kontener redis nie dziala. Uruchom najpierw ./start.sh" >&2
  exit 1
fi

echo "============================================="
echo " Backend DEV mode (hot-reload via nodemon)"
echo "============================================="
echo ""
echo " Bind mount: ${SCRIPT_DIR}/backend -> /app"
echo " nodemon obserwuje zmiany w /app/index.js"
echo " Zmien index.js na hoście -> backend restartuje sie automatycznie"
echo ""

# Uruchom kontener deweloperski:
# - node:20-alpine jako bazowy obraz (nie nasz produkcyjny)
# - bind mount calego katalogu backend/ z hosta do /app w kontenerze
# - instaluje nodemon globalnie i zaleznosci, potem uruchamia nodemon
# - dziala w trybie interaktywnym (-it) aby widziec logi na biezaco
docker run -it --rm \
  --name backend-dev \
  --network "${NETWORK}" \
  -p 3000:3000 \
  -e POSTGRES_HOST=postgres \
  -e POSTGRES_DB=dashboard \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e REDIS_HOST=redis \
  -v "${SCRIPT_DIR}/backend:/app" \
  -w /app \
  node:20-alpine \
  sh -c "npm install --include=dev && npx nodemon --watch index.js --ext js index.js"
