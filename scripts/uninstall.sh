#!/usr/bin/env bash
# uninstall.sh — Remove Password Generator

set -euo pipefail

APP_NAME="password-generator"
INSTALL_DIR="/opt/$APP_NAME"
BIN_LINK="/usr/local/bin/$APP_NAME"
DESKTOP_FILE="/usr/share/applications/$APP_NAME.desktop"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33d'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

[[ $EUID -ne 0 ]] && error "Run as root: sudo bash scripts/uninstall.sh"

[[ ! -d "$INSTALL_DIR" ]] && warn "$APP_NAME does not appear to be installed. Cleaning up anyway."

# ── Confirm ───────────────────────────────────────────────────────────────────
read -rp "Are you sure you want to uninstall Password Generator? [y/N] " confirm
[[ "${confirm,,}" != "y" ]] && { echo "Aborted."; exit 0; }

# ── Remove Python packages ────────────────────────────────────────────────────
if python3 -m pip show customtkinter &>/dev/null 2>&1; then
    info "Removing Python packages..."
    python3 -m pip uninstall -y customtkinter darkdetect
fi

# ── Remove files ──────────────────────────────────────────────────────────────
info "Removing application files..."
rm -rf "$INSTALL_DIR"

[[ -f "$BIN_LINK" ]]      && { info "Removing launcher...";       rm -f "$BIN_LINK"; }
[[ -f "$DESKTOP_FILE" ]]  && { info "Removing desktop entry...";  rm -f "$DESKTOP_FILE"; }

if command -v update-desktop-database &>/dev/null; then
    update-desktop-database /usr/share/applications/ 2>/dev/null || true
fi

echo ""
info "Password Generator has been uninstalled."
