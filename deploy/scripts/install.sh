#!/usr/bin/env bash
# =====================================================================
#  Pierwsza instalacja mateuszkielbasa.dev na serwerze, obok innych aplikacji.
#  Korzysta z istniejącego Caddy w /srv/proxy i sieci "web".
#
#    bash deploy/scripts/install.sh            # obraz z GitHub Container Registry
#    bash deploy/scripts/install.sh --build    # budowa obrazu na serwerze (szybka, strona jest statyczna)
#
#  Można uruchamiać wielokrotnie – nie dubluje wpisu w Caddyfile.
# =====================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROXY_DIR=/srv/proxy
APP_DIR=/srv/apps/mateuszkielbasa
DOMAIN=mateuszkielbasa.dev
BUILD=false
[[ "${1:-}" == "--build" ]] && BUILD=true

log() { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[1;31m%s\033[0m\n' "$*" >&2; exit 1; }

command -v docker >/dev/null || die "Brak Dockera."
[[ -f "$PROXY_DIR/Caddyfile" ]] || die "Nie znaleziono $PROXY_DIR/Caddyfile – najpierw zainstaluj proxy (Caddy)."
docker network inspect web >/dev/null 2>&1 || docker network create web

# ---------------------------------------------------------------------
log "DNS"
DNS_IP="$(getent ahostsv4 "$DOMAIN" | awk 'NR==1{print $1}')"
SERVER_IP="$(curl -s -4 --max-time 5 ifconfig.me || true)"
echo "  $DOMAIN -> ${DNS_IP:-brak rekordu}   serwer: ${SERVER_IP:-?}"
if [[ -z "$DNS_IP" || "$DNS_IP" != "$SERVER_IP" ]]; then
  echo "  UWAGA: domena nie wskazuje na ten serwer. Ustaw rekord A (i www) na $SERVER_IP."
  echo "  Instalacja pójdzie dalej, ale Caddy wystawi certyfikat dopiero po zmianie DNS."
fi

# ---------------------------------------------------------------------
log "Aplikacja w ${APP_DIR}"
sudo mkdir -p "$APP_DIR"
sudo chown "$(id -u):$(id -g)" "$APP_DIR"
cp "$REPO_DIR/deploy/apps/mateuszkielbasa/docker-compose.yml" "$APP_DIR/docker-compose.yml"
touch "$APP_DIR/.env"

cd "$APP_DIR"
if $BUILD; then
  log "Budowanie obrazu na serwerze"
  docker build -t mateuszkielbasa:local "$REPO_DIR"
  grep -q '^APP_IMAGE=' .env && sed -i 's|^APP_IMAGE=.*|APP_IMAGE=mateuszkielbasa:local|' .env || echo 'APP_IMAGE=mateuszkielbasa:local' >> .env
else
  log "Pobieranie obrazu z GitHub Container Registry"
  if ! docker compose pull; then
    echo "Nie udało się pobrać obrazu. Jeśli pakiet jest prywatny, zaloguj się:" >&2
    echo "  echo <TOKEN z read:packages> | docker login ghcr.io -u <login GitHub> --password-stdin" >&2
    die "albo zbuduj obraz na serwerze: bash $0 --build"
  fi
fi

log "Uruchamianie kontenera"
docker compose up -d

log "Czekam, aż strona odpowie…"
ok=false
for _ in $(seq 1 15); do
  if docker exec mateuszkielbasa wget -qO- http://127.0.0.1:8080/healthz >/dev/null 2>&1; then ok=true; break; fi
  sleep 2
done
$ok && echo "Kontener działa." || die "Kontener nie odpowiada: docker compose -f $APP_DIR/docker-compose.yml logs"

# ---------------------------------------------------------------------
log "Caddy: wpis dla $DOMAIN"
if grep -qE "^[[:space:]]*$DOMAIN[[:space:]]*\{" "$PROXY_DIR/Caddyfile"; then
  echo "Wpis już istnieje – pomijam."
else
  BACKUP="$PROXY_DIR/Caddyfile.bak-$(date +%Y%m%d-%H%M%S)"
  cp "$PROXY_DIR/Caddyfile" "$BACKUP"
  # Dopisujemy przez >> (nie sed -i), żeby nie zmienić i-węzła pliku zamontowanego w kontenerze.
  cat "$REPO_DIR/deploy/proxy/Caddyfile.block" >> "$PROXY_DIR/Caddyfile"
  if ! (cd "$PROXY_DIR" && docker compose exec -T caddy caddy validate --config /etc/caddy/Caddyfile >/dev/null); then
    cat "$BACKUP" > "$PROXY_DIR/Caddyfile"
    die "Błędna konfiguracja Caddy – przywrócono poprzedni Caddyfile ($BACKUP)."
  fi
  echo "Kopia poprzedniego pliku: $BACKUP"
fi
(cd "$PROXY_DIR" && docker compose exec -T caddy caddy reload --config /etc/caddy/Caddyfile)

log "Gotowe. Sprawdź https://$DOMAIN"
echo "Aktualizacje: bash $REPO_DIR/deploy/scripts/update.sh"
