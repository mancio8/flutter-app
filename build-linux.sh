#!/usr/bin/env bash
#
# build-linux.sh — Crea la build Linux di release dell'app.
#
# Procedura basata su Nix + Docker (container `flutter` del docker-compose.yml)
# che isola la cartella build/ dal sistema NixOS, evitando problemi di
# permessi e di dipendenze di sistema.
#
# Prerequisiti (una tantum):
#   - Docker avviato
#   - Un utente `nix` per xhost (opzionale, solo per far girare l'app dal
#     container; la build vera e propria non richiede il display)
#
# Uso:
#   ./build-linux.sh
#
# Output:
#   build/linux/x64/release/bundle/   (eseguibile: flutter_starter)
#   + installazione nel profilo Nix (`nix profile add path:.`)
#
set -euo pipefail

# Vai nella directory del progetto (lo script può essere lanciato da ovunque)
cd "$(dirname "$0")"

echo "==> [1/6] Avvio container Docker (flutter)..."
docker compose up -d

echo "==> [2/6] Pulizia progetto nel container..."
docker compose exec -T flutter flutter clean

echo "==> [3/6] Download dipendenze..."
docker compose exec -T flutter flutter pub get

echo "==> [4/6] Build Linux release..."
docker compose exec -T flutter flutter build linux --release

echo "==> [5/6] Copia della build nel filesystem NixOS..."
# Rimuove la build vecchia e copia quella isolata nel volume Docker
# sulla build/ locale (leggibile da Nix).
docker run --rm \
  -v flutter-starter-app_flutter_build:/source:ro \
  -v "$PWD":/dest \
  alpine \
  sh -c 'rm -rf /dest/build && cp -a /source /dest/build'

# La copia avviene come root: systema la proprietà.
if [ -d build ]; then
  echo "==> Systema proprietà di build/..."
  sudo chown -R "$(id -u):$(id -g)" build
fi

echo "==> [6/6] Aggiornamento profilo Nix..."
nix profile remove flutter-starter-app 2>/dev/null || true
nix profile add path:.

echo ""
echo "==> Build Linux completata."
echo "    Eseguibile: build/linux/x64/release/bundle/flutter_starter"
echo "    Installato nel profilo Nix come 'flutter-starter'."