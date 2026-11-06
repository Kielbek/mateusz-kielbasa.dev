#!/usr/bin/env bash
# Aktualizacja strony na serwerze. Uruchom na serwerze:  bash deploy/deploy.sh
# Za pierwszym razem:
#   sudo git clone https://github.com/Kielbek/mateusz-kielbasa.dev.git /opt/mateuszkielbasa.dev
#   sudo chown -R "$USER":"$USER" /opt/mateuszkielbasa.dev   # git działa jako zwykły użytkownik
set -euo pipefail

REPO_DIR=/opt/mateuszkielbasa.dev
WEB_DIR=/var/www/mateuszkielbasa.dev
BRANCH=${1:-main}

cd "$REPO_DIR"
git fetch origin "$BRANCH"
git checkout -q "$BRANCH"
git reset -q --hard "origin/$BRANCH"

sudo mkdir -p "$WEB_DIR"
sudo rsync -a --delete --exclude '.git' --exclude 'deploy' --exclude 'README.md' "$REPO_DIR"/ "$WEB_DIR"/
echo "Pliki skopiowane do $WEB_DIR ($(git rev-parse --short HEAD))."

if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx caddy || sudo docker ps --format '{{.Names}}' | grep -qx caddy; then
  # Caddy serwuje pliki prosto z zamontowanego katalogu — przeładowanie niepotrzebne.
  echo "Gotowe: https://mateuszkielbasa.dev (Caddy)"
elif command -v nginx >/dev/null 2>&1; then
  sudo nginx -t
  sudo systemctl reload nginx
  echo "Gotowe: https://mateuszkielbasa.dev (nginx)"
else
  echo "UWAGA: nie znaleziono Caddy ani nginx — serwer WWW trzeba skonfigurować osobno." >&2
  exit 1
fi
