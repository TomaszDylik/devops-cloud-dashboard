#!/usr/bin/env bash
# =============================================================================
# backup.sh – tworzy backup woluminu pg-data (PostgreSQL) do archiwum .tar.gz
#
# Uzywa kontenera alpine do zamontowania woluminu i spakowania jego zawartosci.
# Kopie zapisywane w ./backups/ z sygnatura czasowa.
# =============================================================================
set -euo pipefail

VOLUME_NAME="pg-data"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/backups"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="pg-backup-${TIMESTAMP}.tar.gz"

# Sprawdz czy wolumin istnieje
if ! docker volume inspect "${VOLUME_NAME}" >/dev/null 2>&1; then
  echo "BLAD: Wolumin ${VOLUME_NAME} nie istnieje." >&2
  exit 1
fi

# Utworz katalog backups/ jesli nie istnieje
mkdir -p "${BACKUP_DIR}"

echo "============================================="
echo " Backup woluminu: ${VOLUME_NAME}"
echo "============================================="
echo ""
echo " Plik docelowy: backups/${BACKUP_FILE}"
echo ""

# Zamontuj wolumin i katalog backups/ w kontenerze alpine,
# spakuj zawartosc woluminu do archiwum tar.gz
docker run --rm \
  -v "${VOLUME_NAME}:/data:ro" \
  -v "${BACKUP_DIR}:/backup" \
  alpine \
  tar czf "/backup/${BACKUP_FILE}" -C /data .

# Sprawdz czy plik zostal utworzony
if [ -f "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
  SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_FILE}" | cut -f1)
  echo "Backup GOTOWY: backups/${BACKUP_FILE} (${SIZE})"
else
  echo "BLAD: Backup nie zostal utworzony." >&2
  exit 1
fi
