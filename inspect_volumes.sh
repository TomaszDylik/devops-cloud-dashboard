#!/usr/bin/env bash
# =============================================================================
# inspect_volumes.sh – wyswietla informacje o woluminach Docker
#
# Dla kazdego woluminu uzywanego przez aplikacje pokazuje:
# - Nazwe i mountpoint
# - Rozmiar danych
# - Kontenery korzystajace z woluminu
# =============================================================================
set -euo pipefail

VOLUMES=("pg-data" "backend-logs")

echo "============================================="
echo " Inspekcja woluminow Docker"
echo "============================================="
echo ""

for VOL in "${VOLUMES[@]}"; do
  echo "---------------------------------------------"
  echo " Wolumin: ${VOL}"
  echo "---------------------------------------------"

  # Sprawdz czy wolumin istnieje
  if ! docker volume inspect "${VOL}" >/dev/null 2>&1; then
    echo "  Status: NIE ISTNIEJE"
    echo ""
    continue
  fi

  # Mountpoint
  MOUNTPOINT=$(docker volume inspect "${VOL}" --format '{{.Mountpoint}}')
  echo "  Mountpoint: ${MOUNTPOINT}"

  # Data utworzenia
  CREATED=$(docker volume inspect "${VOL}" --format '{{.CreatedAt}}')
  echo "  Utworzony:   ${CREATED}"

  # Rozmiar danych (przez kontener alpine)
  SIZE=$(docker run --rm -v "${VOL}:/data:ro" alpine du -sh /data 2>/dev/null | cut -f1)
  echo "  Rozmiar:    ${SIZE}"

  # Kontenery korzystajace z tego woluminu
  CONTAINERS=$(docker ps -a --filter "volume=${VOL}" --format '{{.Names}} ({{.Status}})' 2>/dev/null)
  if [ -n "${CONTAINERS}" ]; then
    echo "  Kontenery:"
    echo "${CONTAINERS}" | while read -r line; do
      echo "    - ${line}"
    done
  else
    echo "  Kontenery:  (brak)"
  fi

  # Zawartosc katalogu glownego woluminu (max 10 elementow)
  echo "  Zawartosc (top-level):"
  docker run --rm -v "${VOL}:/data:ro" alpine ls -la /data 2>/dev/null | head -12 | while read -r line; do
    echo "    ${line}"
  done

  echo ""
done

# Dodatkowo pokaz tmpfs i bind mounty
echo "---------------------------------------------"
echo " Inne mounty (tmpfs / bind)"
echo "---------------------------------------------"
echo ""

for CONTAINER in redis backend frontend backend-dev; do
  if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    MOUNTS=$(docker inspect "${CONTAINER}" --format '{{range .Mounts}}{{.Type}}:{{.Source}}->{{.Destination}} {{end}}' 2>/dev/null)
    if [ -n "${MOUNTS}" ]; then
      echo "  ${CONTAINER}:"
      for M in ${MOUNTS}; do
        echo "    - ${M}"
      done
    fi
  fi
done

echo ""
echo "============================================="
echo " Podsumowanie: docker volume ls"
echo "============================================="
docker volume ls --format "table {{.Name}}\t{{.Driver}}\t{{.Mountpoint}}" | head -20
