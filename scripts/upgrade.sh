#!/usr/bin/env bash
# upgrade.sh — Upgrade Password Generator to the latest version

set -euo pipefail

APP_NAME="password-generator"
INSTALL_DIR="/opt/$APP_NAME"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

[[ $EUID -ne 0 ]] && error "Run as root: sudo bash scripts/upgrade.sh"

[[ ! -d "$INSTALL_DIR" ]] && error "$APP_NAME is not installed. Run install.sh first."

info "Upgrading Python dependencies..."
python3 -m pip install --quiet --upgrade -r "$INSTALL_DIR/requirements.txt"

info "Updating application files..."
cp "$PROJECT_DIR/app.py"                "$INSTALL_DIR/"
cp "$PROJECT_DIR/password_generator.py" "$INSTALL_DIR/"
cp "$PROJECT_DIR/requirements.txt"      "$INSTALL_DIR/"
[[ -f "$PROJECT_DIR/icon.png" ]] && cp "$PROJECT_DIR/icon.png" "$INSTALL_DIR/"

DESKTOP_DEST="/usr/share/applications/password-generator.desktop"
[[ -f "$PROJECT_DIR/password-generator.desktop" ]] && \
    cp "$PROJECT_DIR/password-generator.desktop" "$DESKTOP_DEST" && \
    info "Desktop entry updated."

if command -v update-desktop-database &>/dev/null; then
    update-desktop-database /usr/share/applications/ 2>/dev/null || true
fi

echo ""
info "Upgrade complete! Restart the app to apply changes."
