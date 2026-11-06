#!/usr/bin/env bash
# Aktualizacja mateuszkielbasa.dev do najnowszej wersji – kilka sekund przerwy.
#   bash ~/mateusz-kielbasa.dev/deploy/scripts/update.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd /srv/apps/mateuszkielbasa

if grep -q '^APP_IMAGE=mateuszkielbasa:local' .env 2>/dev/null; then
  # Tryb --build: pobierz kod z GitHuba i zbuduj obraz na serwerze.
  git -C "$REPO_DIR" pull --ff-only
  docker build -t mateuszkielbasa:local "$REPO_DIR"
else
  docker compose pull
fi
docker compose up -d
docker image prune -f >/dev/null
docker compose ps
