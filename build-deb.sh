#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Crea un pacchetto .deb da una build Flutter Linux --release
# ============================================================

# Nome valido per Debian
PACKAGE_NAME="flutter-starter"

# Nome visualizzato
APP_NAME="Flutter Starter"

# Nome reale dell'eseguibile prodotto da Flutter
EXECUTABLE_NAME="flutter_starter"

VERSION="1.0.0"
ARCH="amd64"
DESCRIPTION="Applicazione Flutter Starter"

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BUNDLE_DIR="$PROJECT_DIR/build/linux/x64/release/bundle"

PKG_ROOT="$PROJECT_DIR/build/deb/${PACKAGE_NAME}_${VERSION}_${ARCH}"

INSTALL_DIR="/opt/${PACKAGE_NAME}"

OUTPUT_DEB="$PROJECT_DIR/build/deb/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"


# ============================================================
# Controllo build
# ============================================================

echo "==> Controllo build Flutter..."

if [[ ! -d "$BUNDLE_DIR" ]]; then
    echo "ERRORE: bundle non trovata:"
    echo "$BUNDLE_DIR"
    exit 1
fi

EXECUTABLE="$BUNDLE_DIR/$EXECUTABLE_NAME"

if [[ ! -f "$EXECUTABLE" ]]; then
    echo "ERRORE: non trovo l'eseguibile:"
    echo "$EXECUTABLE"
    echo
    echo "Contenuto della bundle:"
    ls -la "$BUNDLE_DIR"
    exit 1
fi

echo "==> Eseguibile trovato:"
echo "    $EXECUTABLE"


# ============================================================
# Pulizia
# ============================================================

echo "==> Pulizia directory precedente..."

rm -rf "$PKG_ROOT"
rm -f "$OUTPUT_DEB"


# ============================================================
# Struttura Debian
# ============================================================

echo "==> Creazione struttura Debian..."

mkdir -p \
    "$PKG_ROOT/DEBIAN" \
    "$PKG_ROOT$INSTALL_DIR" \
    "$PKG_ROOT/usr/share/applications"


# ============================================================
# Copia build Flutter
# ============================================================

echo "==> Copia della build Flutter..."

cp -a "$BUNDLE_DIR"/. "$PKG_ROOT$INSTALL_DIR/"


# ============================================================
# CONTROL
# ============================================================

echo "==> Creazione control..."

cat > "$PKG_ROOT/DEBIAN/control" <<EOF
Package: ${PACKAGE_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Maintainer: Vincenzo Mancinelli
Description: ${DESCRIPTION}
 Applicazione desktop sviluppata con Flutter.
EOF


# ============================================================
# DESKTOP ENTRY
# ============================================================

echo "==> Creazione launcher..."

cat > "$PKG_ROOT/usr/share/applications/${PACKAGE_NAME}.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=${APP_NAME}
Comment=${DESCRIPTION}
Exec=${INSTALL_DIR}/${EXECUTABLE_NAME}
Terminal=false
Categories=Utility;
StartupWMClass=${EXECUTABLE_NAME}
EOF


# ============================================================
# Permessi
# ============================================================

chmod 755 "$PKG_ROOT$INSTALL_DIR/$EXECUTABLE_NAME"
chmod 644 "$PKG_ROOT/usr/share/applications/${PACKAGE_NAME}.desktop"


# ============================================================
# POSTINSTALL
# ============================================================

echo "==> Creazione script postinst..."

cat > "$PKG_ROOT/DEBIAN/postinst" <<EOF
#!/bin/sh
set -e

chmod 755 "${INSTALL_DIR}/${EXECUTABLE_NAME}"

exit 0
EOF

chmod 755 "$PKG_ROOT/DEBIAN/postinst"


# ============================================================
# Creazione DEB
# ============================================================

echo "==> Creazione .deb..."

mkdir -p "$PROJECT_DIR/build/deb"

dpkg-deb --build --root-owner-group \
    "$PKG_ROOT" \
    "$OUTPUT_DEB"


# ============================================================
# Risultato
# ============================================================

echo
echo "=============================================="
echo "  PACCHETTO CREATO"
echo "=============================================="
echo
echo "  $OUTPUT_DEB"
echo
echo "Installazione su Ubuntu:"
echo
echo "  sudo apt install ./build/deb/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
echo
echo "Disinstallazione:"
echo
echo "  sudo apt remove ${PACKAGE_NAME}"
echo