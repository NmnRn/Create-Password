#!/usr/bin/env bash
# uninstall.sh — Remove Password Generator

set -euo pipefail

APP_NAME="password-generator"
INSTALL_DIR="/opt/$APP_NAME"
VENV_DIR="$INSTALL_DIR/venv"
BIN_LINK="/usr/local/bin/$APP_NAME"
DESKTOP_FILE="/usr/share/applications/$APP_NAME.desktop"
AUTO_YES=0
SHOW_PIP_FREEZE=0

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

usage() {
    cat <<EOF
Usage: uninstall.sh [--yes] [--show-pip]

Options:
  --yes        Do not prompt for confirmation
  --show-pip   Print installed packages before removal
EOF
}

for arg in "$@"; do
    case "$arg" in
        --yes) AUTO_YES=1 ;;
        --show-pip) SHOW_PIP_FREEZE=1 ;;
        -h|--help) usage; exit 0 ;;
        *) error "Unknown option: $arg" ;;
    esac
done

[[ $EUID -ne 0 ]] && error "Run as root: sudo bash scripts/uninstall.sh"

[[ ! -d "$INSTALL_DIR" ]] && warn "$APP_NAME does not appear to be installed. Cleaning up anyway."

# ── Confirm ───────────────────────────────────────────────────────────────────
if [[ "$AUTO_YES" -eq 0 ]]; then
    read -rp "Are you sure you want to uninstall Password Generator? [y/N] " confirm
    [[ "${confirm,,}" != "y" ]] && { echo "Aborted."; exit 0; }
fi

# ── Remove Python packages ────────────────────────────────────────────────────
if [[ -x "$VENV_DIR/bin/python" ]]; then
    if [[ "$SHOW_PIP_FREEZE" -eq 1 ]]; then
        "$VENV_DIR/bin/python" -m pip freeze || true
    fi
    if "$VENV_DIR/bin/python" -m pip show customtkinter &>/dev/null 2>&1; then
        info "Removing Python packages from venv..."
        "$VENV_DIR/bin/python" -m pip uninstall -y customtkinter darkdetect
    fi
elif command -v python3.13 &>/dev/null; then
    if [[ "$SHOW_PIP_FREEZE" -eq 1 ]]; then
        python3.13 -m pip freeze || true
    fi
    if python3.13 -m pip show customtkinter &>/dev/null 2>&1; then
        info "Removing Python packages (system Python 3.13)..."
        python3.13 -m pip uninstall -y customtkinter darkdetect
    fi
else
    warn "python3.13 not found; skipping pip package removal."
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
