#!/usr/bin/env bash
# Arch Linux upgrade script

set -euo pipefail

APP_NAME="password-generator"
TARGET_USER="${SUDO_USER:-$USER}"
INSTALL_DIR="/home/$TARGET_USER/$APP_NAME"
VENV_DIR="$INSTALL_DIR/venv"
DESKTOP_FILE="/usr/share/applications/$APP_NAME.desktop"
REPO_BASE="https://raw.githubusercontent.com/NmnRn/Create-Password/main"
AUTO_YES=0
TEMP_DIR=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

usage() {
    cat <<EOF
Usage: upgrade.sh [--yes]

Options:
  --yes   Do not prompt for confirmation
EOF
}

for arg in "$@"; do
    case "$arg" in
        --yes) AUTO_YES=1 ;;
        -h|--help) usage; exit 0 ;;
        *) error "Unknown option: $arg" ;;
    esac
done

[[ $EUID -ne 0 ]] && error "Run as root: sudo bash upgrade.sh"
[[ ! -d "$INSTALL_DIR" ]] && error "$APP_NAME is not installed. Run install.sh first."
[[ ! -x "$VENV_DIR/bin/python" ]] && error "Venv python not found at $VENV_DIR/bin/python"

fetch() {
    local url="$1" dest="$2"
    curl -fSL --retry 3 --retry-delay 1 "$url" -o "$dest"
}

update_repos() {
    info "Updating package repositories..."
    pacman -Sy --noconfirm
}

health_check() {
    info "Running health check..."
    PYTHONPATH="$INSTALL_DIR" "$VENV_DIR/bin/python" - <<'PY'
import customtkinter
import darkdetect
import password_generator
print("Health check OK")
PY
}

write_desktop() {
    local icon_line=""
    if [[ -f "$INSTALL_DIR/icon.png" ]]; then
        icon_line="Icon=$INSTALL_DIR/icon.png"
    fi

    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Password Generator
GenericName=Password Generator
Comment=Secure password generator - create strong passwords instantly
Exec=/usr/local/bin/password-generator
${icon_line}
Terminal=false
StartupNotify=false
Categories=Utility;Security;
Keywords=password;generator;security;
EOF
}

update_repos

if [[ "$AUTO_YES" -eq 0 ]]; then
    read -rp "Upgrade Password Generator in $INSTALL_DIR? [y/N] " confirm
    [[ "${confirm,,}" != "y" ]] && { echo "Aborted."; exit 0; }
fi

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT
fetch "$REPO_BASE/app.py" "$TEMP_DIR/app.py"
fetch "$REPO_BASE/password_generator.py" "$TEMP_DIR/password_generator.py"
fetch "$REPO_BASE/requirements.txt" "$TEMP_DIR/requirements.txt"
fetch "$REPO_BASE/password-generator.desktop" "$TEMP_DIR/password-generator.desktop"
fetch "$REPO_BASE/icon.png" "$TEMP_DIR/icon.png" || true

info "Upgrading Python dependencies..."
"$VENV_DIR/bin/python" -m pip install --quiet --upgrade -r "$TEMP_DIR/requirements.txt"

info "Updating application files..."
cp "$TEMP_DIR/app.py"                "$INSTALL_DIR/"
cp "$TEMP_DIR/password_generator.py" "$INSTALL_DIR/"
cp "$TEMP_DIR/requirements.txt"      "$INSTALL_DIR/"
[[ -f "$TEMP_DIR/icon.png" ]] && cp "$TEMP_DIR/icon.png" "$INSTALL_DIR/"

info "Updating desktop entry..."
write_desktop

if command -v update-desktop-database &>/dev/null; then
    update-desktop-database /usr/share/applications/ 2>/dev/null || true
fi

echo ""
info "Upgrade complete! Restart the app to apply changes."
health_check
