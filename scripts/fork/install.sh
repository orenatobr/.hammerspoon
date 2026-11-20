#!/bin/bash
# Installs the fork's Hammerspoon.app and its personal config.
# Usage: curl -fsSL https://raw.githubusercontent.com/orenatobr/hammerspoon/main/scripts/fork/install.sh | bash
set -euo pipefail

REPO="orenatobr/hammerspoon"
APP_DIR="${APP_DIR:-/Applications}"
CONFIG_DIR="${HOME}/.hammerspoon"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

echo "Downloading the latest release of ${REPO}..."
curl -fsSL "https://github.com/${REPO}/releases/latest/download/Hammerspoon.app.zip" -o "${TMP}/app.zip"
TAG="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest")"
TAG="${TAG##*/}"
curl -fsSL "https://github.com/${REPO}/archive/refs/tags/${TAG}.tar.gz" -o "${TMP}/source.tar.gz"
mkdir "${TMP}/src"
tar -xzf "${TMP}/source.tar.gz" -C "${TMP}/src" --strip-components=1

echo "Installing Hammerspoon.app into ${APP_DIR}..."
pkill -x Hammerspoon 2>/dev/null || true
rm -rf "${APP_DIR}/Hammerspoon.app"
ditto -x -k "${TMP}/app.zip" "${APP_DIR}"
xattr -dr com.apple.quarantine "${APP_DIR}/Hammerspoon.app" 2>/dev/null || true

echo "Installing config into ${CONFIG_DIR}..."
mkdir -p "${CONFIG_DIR}"
if [ -f "${CONFIG_DIR}/init.lua" ]; then
    BACKUP="${CONFIG_DIR}.backup-$(date +%Y%m%d%H%M%S)"
    cp -R "${CONFIG_DIR}" "${BACKUP}"
    echo "Existing config backed up to ${BACKUP}"
fi
cp -R "${TMP}/src/config/." "${CONFIG_DIR}/"

open "${APP_DIR}/Hammerspoon.app"
echo "Done. Grant Accessibility permission to Hammerspoon when macOS asks."
