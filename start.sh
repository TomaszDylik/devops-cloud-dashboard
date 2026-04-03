#!/usr/bin/env bash
set -euo pipefail

# Konfiguracja
DOCKER_USERNAME="${DOCKER_USERNAME:-tomekdylik}"
BACKEND_IMAGE="${DOCKER_USERNAME}/devops-cloud-dashboard-backend:v2"
FRONTEND_IMAGE="${DOCKER_USERNAME}/devops-cloud-dashboard-frontend:v2"

NETWORK="dashboard-net"
PG_VOLUME="pg-data"          
BACKEND_LOG_VOLUME="backend-logs"

BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
VERSION="2.0.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo " DevOps Cloud Dashboard v2 – start"
echo " Backend image : ${BACKEND_IMAGE}"
echo " Frontend image: ${FRONTEND_IMAGE}"


# Budowanie obrazów (wieloplatformowo) i push do rejestru
echo ""
echo "[1/7] Budowanie i publikowanie obrazu backendu..."
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg BUILD_DATE="${BUILD_DATE}" \
  --build-arg VERSION="${VERSION}" \
  --tag "${BACKEND_IMAGE}" \
  --push \
  "${SCRIPT_DIR}/backend"

echo ""
echo "[2/7] Budowanie i publikowanie obrazu frontendu..."
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg BUILD_DATE="${BUILD_DATE}" \
  --build-arg VERSION="${VERSION}" \
  --tag "${FRONTEND_IMAGE}" \
  --push \
  "${SCRIPT_DIR}/frontend"

# Sprzątanie starych kontenerów
echo ""
echo "[3/7] Usuwanie starych kontenerów (jeśli istnieją)..."
docker rm -f postgres redis backend frontend 2>/dev/null || true

# Sieć i woluminy
echo ""
echo "[4/7] Tworzenie sieci i woluminów..."
docker network create "${NETWORK}" 2>/dev/null || echo "  Sieć '${NETWORK}' już istnieje."
docker volume create "${PG_VOLUME}" 2>/dev/null || echo "  Wolumen '${PG_VOLUME}' już istnieje."
docker volume create "${BACKEND_LOG_VOLUME}" 2>/dev/null || echo "  Wolumen '${BACKEND_LOG_VOLUME}' już istnieje."

# PostgreSQL
echo ""
echo "[5/7] Uruchamianie PostgreSQL..."
docker run -d \
  --name postgres \
  --network "${NETWORK}" \
  --restart unless-stopped \
  -e POSTGRES_DB=dashboard \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -v "${PG_VOLUME}:/var/lib/postgresql/data" \
  postgres:16-alpine

# Czekamy aż PostgreSQL będzie gotowy
echo "  Czekam na gotowość PostgreSQL..."
for i in $(seq 1 30); do
  if docker exec postgres pg_isready -U postgres -q 2>/dev/null; then
    echo "  PostgreSQL gotowy (próba ${i}/30)."
    break
  fi
  if [ "${i}" -eq 30 ]; then
    echo "  BŁĄD: PostgreSQL nie uruchomił się w czasie 60s." >&2
    exit 1
  fi
  sleep 2
done


# Redis
echo ""
echo "[5b/7] Uruchamianie Redis (tmpfs – dane ulotne)..."
docker run -d \
  --name redis \
  --network "${NETWORK}" \
  --restart unless-stopped \
  --tmpfs /data:rw,size=64m \
  redis:7-alpine

# Backend Node.js
echo ""
echo "[6/7] Uruchamianie backendu..."
docker run -d \
  --name backend \
  --network "${NETWORK}" \
  --restart unless-stopped \
  -p 3000:3000 \
  -e POSTGRES_HOST=postgres \
  -e POSTGRES_DB=dashboard \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e REDIS_HOST=redis \
  -v "${BACKEND_LOG_VOLUME}:/app/logs" \
  --tmpfs /tmp:rw,size=32m \
  "${BACKEND_IMAGE}"

# Frontend (Nginx)
echo ""
echo "[7/7] Uruchamianie frontendu (Nginx)..."
docker run -d \
  --name frontend \
  --network "${NETWORK}" \
  --restart unless-stopped \
  -p 80:8080 \
  -v "${SCRIPT_DIR}/frontend/nginx.conf:/etc/nginx/conf.d/default.conf" \
  --tmpfs /var/cache/nginx:rw,size=64m,uid=101,gid=101,mode=755 \
  "${FRONTEND_IMAGE}"


# Podsumowanie
echo ""
echo "================================================================="
echo " Środowisko uruchomione!"
echo ""
echo " Frontend (Nginx) : http://localhost"
echo " Backend API      : http://localhost:3000"
echo ""
echo " Weryfikacja:"
echo "   curl http://localhost:3000/health"
echo "   curl -v http://localhost:3000/stats   # X-Cache: MISS"
echo "   curl -v http://localhost:3000/stats   # X-Cache: HIT (w ciągu 10s)"
echo "================================================================="
