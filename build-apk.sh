#!/usr/bin/env bash
#
# build-apk.sh — Crea l'APK di release dell'app (build diretta, no Docker).
#
# Su NixOS il PATH di sistema può puntare a Java 8, che non basta per
# Gradle 8.7.3 (richiede Java 11+). Questo script rileva automaticamente
# una JDK 17+ nel Nix store e la usa per la build, senza modificare
# configuration.nix e senza bisogno di sudo.
#
# Le credenziali Supabase (SUPABASE_URL, SUPABASE_ANON_KEY) vengono lette
# dal file .env e iniettate a compile-time con --dart-define, così il file
# .env NON finisce nel bundle dell'APK.
#
# Uso:
#   ./build-apk.sh
#
# Output:
#   build/app/outputs/flutter-apk/app-release.apk
#
set -euo pipefail

# Vai nella directory del progetto (lo script può essere lanciato da ovunque)
cd "$(dirname "$0")"

# --- Rileva una JDK 17+ nel Nix store --------------------------------
JDK_HOME=""

for candidate in \
  /nix/store/*openjdk-17*/bin/java \
  /nix/store/*openjdk-21*/bin/java \
  /nix/store/*openjdk-22*/bin/java \
  /nix/store/*openjdk-23*/bin/java; do
  if [ -x "$candidate" ]; then
    # Deriva JAVA_HOME dalla posizione del binario java (…/bin/java -> …)
    JDK_HOME="$(dirname "$(dirname "$candidate")")"
    break
  fi
done

# Fallback: se nessuna JDK 17+ è nel Nix store, usa la JAVA_HOME corrente
# (se punta a Java 11+).
if [ -z "$JDK_HOME" ]; then
  if [ -n "${JAVA_HOME:-}" ] && "$JAVA_HOME/bin/java" -version 2>&1 | grep -qE 'version "(1[1-9]|[2-9][0-9])'; then
    JDK_HOME="$JAVA_HOME"
  else
    echo "ERRORE: nessuna JDK 17+ trovata nel Nix store e JAVA_HOME non è valido."
    echo "Installa una JDK 17+ (es. 'nix profile add nixpkgs#jdk17') o imposta JAVA_HOME."
    exit 1
  fi
fi

echo "==> JDK rilevata: $JDK_HOME"
"$JDK_HOME/bin/java" -version 2>&1 | head -1
echo ""

# --- Legge le credenziali Supabase da .env ---------------------------
SUPABASE_URL=""
SUPABASE_ANON_KEY=""

if [ -f .env ]; then
  # Carica le variabili dal .env (senza processarle come script)
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
  SUPABASE_URL="${SUPABASE_URL:-}"
  SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
fi

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "ERRORE: SUPABASE_URL e SUPABASE_ANON_KEY mancanti."
  echo "Crea un file .env nella root (vedi .env.example) oppure esporta le variabili:"
  echo "  export SUPABASE_URL=https://<project-ref>.supabase.co"
  echo "  export SUPABASE_ANON_KEY=<anon-key>"
  exit 1
fi

echo "==> Credenziali Supabase caricate da .env"
echo ""

# --- Pulizia e build -------------------------------------------------
echo "==> [1/3] Pulizia progetto..."
flutter clean

echo "==> [2/3] Download dipendenze..."
flutter pub get

echo "==> [3/3] Build APK release..."
JAVA_HOME="$JDK_HOME" flutter build apk --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

echo ""
echo "==> APK creato con successo:"
ls -lh build/app/outputs/flutter-apk/app-release.apk