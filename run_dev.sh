#!/usr/bin/env bash
# =============================================================================
# run_dev.sh – uruchamia backend Java w trybie deweloperskim
#
# Bind mount kodu z hosta (./backend) do kontenera.
# Maven kompiluje i uruchamia aplikacje Spring Boot.
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
echo " Backend DEV mode (Spring Boot via Maven)"
echo "============================================="
echo ""
echo " Bind mount: ${SCRIPT_DIR}/backend -> /app"
echo " mvn spring-boot:run buduje i uruchamia aplikacje"
echo ""

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
  eclipse-temurin:21-jdk-alpine \
  sh -c "apk add --no-cache maven && mvn spring-boot:run -B"
