#!/usr/bin/env bash
# Aktualizacja strony na serwerze. Uruchom na serwerze:  bash deploy/deploy.sh
# Za pierwszym razem:
#   sudo git clone https://github.com/Kielbek/mateusz-kielbasa.dev.git /opt/mateuszkielbasa.dev
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
sudo nginx -t && sudo systemctl reload nginx
echo "Wdrożono $(git rev-parse --short HEAD) na https://mateuszkielbasa.dev"
