#!/usr/bin/env bash
# upgrade.sh — Upgrade Password Generator to the latest version

set -euo pipefail

APP_NAME="password-generator"
INSTALL_DIR="/opt/$APP_NAME"
VENV_DIR="$INSTALL_DIR/venv"
PYTHON_BIN="python3.13"
SCRIPT_PATH="${BASH_SOURCE[0]-}"
if [[ -n "$SCRIPT_PATH" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
else
    SCRIPT_DIR="$PWD"
fi
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TEMP_DIR=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }
health_check() {
    info "Running health check..."
    "$VENV_DIR/bin/python" - <<'PY'
import customtkinter
import darkdetect
import password_generator
print("Health check OK")
PY
}
usage() {
    cat <<EOF
Usage: upgrade.sh [--yes]

Options:
  --yes   Do not prompt for confirmation
EOF
}

AUTO_YES=0
for arg in "$@"; do
    case "$arg" in
        --yes) AUTO_YES=1 ;;
        -h|--help) usage; exit 0 ;;
        *) error "Unknown option: $arg" ;;
    esac
done
require_cmd() { command -v "$1" &>/dev/null || error "Missing command: $1"; }
fetch() {
    local url="$1" dest="$2"
    curl -fSL --retry 3 --retry-delay 1 "$url" -o "$dest"
}

[[ $EUID -ne 0 ]] && error "Run as root: sudo bash scripts/upgrade.sh"

[[ ! -d "$INSTALL_DIR" ]] && error "$APP_NAME is not installed. Run install.sh first."
[[ ! -d "$VENV_DIR" ]] && error "Virtual environment not found at $VENV_DIR. Reinstall first."

if [[ "$AUTO_YES" -eq 0 ]]; then
    read -rp "Upgrade Password Generator in $INSTALL_DIR? [y/N] " confirm
    [[ "${confirm,,}" != "y" ]] && { echo "Aborted."; exit 0; }
fi

# ── Source files (local or remote) ───────────────────────────────────────────
if [[ ! -f "$PROJECT_DIR/app.py" ]]; then
    require_cmd curl

    warn "Local project files not found; downloading from GitHub..."
    TEMP_DIR="$(mktemp -d)"
    trap '[[ -n "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"' EXIT

    REPO_BASE="https://raw.githubusercontent.com/NmnRn/Create-Password/main"
    fetch "$REPO_BASE/app.py" "$TEMP_DIR/app.py"
    fetch "$REPO_BASE/password_generator.py" "$TEMP_DIR/password_generator.py"
    fetch "$REPO_BASE/requirements.txt" "$TEMP_DIR/requirements.txt"
    fetch "$REPO_BASE/password-generator.desktop" "$TEMP_DIR/password-generator.desktop"
    fetch "$REPO_BASE/icon.png" "$TEMP_DIR/icon.png" || true

    PROJECT_DIR="$TEMP_DIR"
fi

for required in app.py password_generator.py requirements.txt password-generator.desktop; do
    [[ -f "$PROJECT_DIR/$required" ]] || error "Missing required file: $PROJECT_DIR/$required"
done

info "Upgrading Python dependencies..."
[[ ! -x "$VENV_DIR/bin/python" ]] && error "Venv python not found at $VENV_DIR/bin/python"
"$VENV_DIR/bin/python" -m pip install --quiet --upgrade -r "$INSTALL_DIR/requirements.txt"

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
health_check
