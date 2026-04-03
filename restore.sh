#!/usr/bin/env bash
# =============================================================================
# restore.sh – przywraca backup woluminu pg-data z archiwum .tar.gz
#
# Uzycie: ./restore.sh backups/pg-backup-YYYYMMDD_HHMMSS.tar.gz
#
# 1. Zatrzymuje kontener postgres (jesli dziala)
# 2. Czysci wolumin pg-data
# 3. Rozpakowuje archiwum do woluminu
# 4. Restartuje postgres
# 5. Weryfikuje dostepnosc bazy danych
# =============================================================================
set -euo pipefail

VOLUME_NAME="pg-data"
NETWORK="dashboard-net"

# Sprawdz argument
if [ $# -lt 1 ]; then
  echo "Uzycie: $0 <sciezka-do-backupu.tar.gz>" >&2
  echo "Przyklad: $0 backups/pg-backup-20250101_120000.tar.gz" >&2
  exit 1
fi

BACKUP_PATH="$1"

if [ ! -f "${BACKUP_PATH}" ]; then
  echo "BLAD: Plik ${BACKUP_PATH} nie istnieje." >&2
  exit 1
fi

# Uzyj sciezki bezwzglednej
BACKUP_FULL="$(cd "$(dirname "${BACKUP_PATH}")" && pwd)/$(basename "${BACKUP_PATH}")"

echo "============================================="
echo " Przywracanie backupu do woluminu: ${VOLUME_NAME}"
echo "============================================="
echo ""
echo " Plik zrodlowy: ${BACKUP_PATH}"
echo ""

# 1. Zatrzymaj postgres jesli dziala
if docker ps --format '{{.Names}}' | grep -q '^postgres$'; then
  echo "[1/5] Zatrzymywanie kontenera postgres..."
  docker stop postgres >/dev/null
  docker rm postgres >/dev/null 2>&1 || true
else
  echo "[1/5] Kontener postgres nie dziala - pomijam zatrzymanie."
  docker rm postgres >/dev/null 2>&1 || true
fi

# 2. Usun stary wolumin i stworz na nowo (czysta kopia)
echo "[2/5] Czyszczenie woluminu ${VOLUME_NAME}..."
docker volume rm "${VOLUME_NAME}" 2>/dev/null || true
docker volume create "${VOLUME_NAME}" >/dev/null

# 3. Rozpakuj archiwum do woluminu
echo "[3/5] Rozpakowywanie backupu do woluminu..."
docker run --rm \
  -v "${VOLUME_NAME}:/data" \
  -v "${BACKUP_FULL}:/backup.tar.gz:ro" \
  alpine \
  sh -c "tar xzf /backup.tar.gz -C /data"

# 4. Uruchom postgres z przywroconym woluminem
echo "[4/5] Uruchamianie kontenera postgres..."
docker network create "${NETWORK}" 2>/dev/null || true
docker run -d \
  --name postgres \
  --network "${NETWORK}" \
  -e POSTGRES_DB=dashboard \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -v "${VOLUME_NAME}:/var/lib/postgresql/data" \
  postgres:16-alpine >/dev/null

# 5. Weryfikacja dostepnosci bazy
echo "[5/5] Weryfikacja dostepnosci bazy danych..."
RETRIES=15
for i in $(seq 1 $RETRIES); do
  if docker exec postgres pg_isready -U postgres >/dev/null 2>&1; then
    echo ""
    echo "Przywracanie GOTOWE. Baza danych jest dostepna."

    # Pokaz zawartosc tabeli items (jesli istnieje)
    echo ""
    echo "Zawartosc tabeli items:"
    docker exec postgres psql -U postgres -d dashboard \
      -c "SELECT * FROM items;" 2>/dev/null || echo "(tabela items nie istnieje jeszcze)"
    exit 0
  fi
  sleep 1
done

echo "OSTRZEZENIE: Baza danych nie odpowiada po ${RETRIES}s. Sprawdz kontener: docker logs postgres" >&2
exit 1
