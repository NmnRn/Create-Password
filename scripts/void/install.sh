#!/usr/bin/env bash
# Void Linux install script

set -euo pipefail

APP_NAME="password-generator"
TARGET_USER="${SUDO_USER:-$USER}"
INSTALL_DIR="/home/$TARGET_USER/$APP_NAME"
VENV_DIR="$INSTALL_DIR/venv"
BIN_LINK="/usr/local/bin/$APP_NAME"
DESKTOP_FILE="/usr/share/applications/$APP_NAME.desktop"
REPO_BASE="https://raw.githubusercontent.com/NmnRn/Create-Password/main"
MIN_PY=311
PYTHON_BIN=""
AUTO_YES=0
TEMP_DIR=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

usage() {
    cat <<EOF
Usage: install.sh [--yes]

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

if [[ ! -t 0 || -p /dev/stdin ]]; then
    AUTO_YES=1
fi

[[ $EUID -ne 0 ]] && error "Run as root: sudo bash install.sh"

fetch() {
    local url="$1" dest="$2"
    curl -fSL --retry 3 --retry-delay 1 "$url" -o "$dest"
}

update_repos() {
    info "Updating package repositories..."
    xbps-install -Sy
}

install_system_deps() {
    info "Installing system dependencies..."
    xbps-install -Sy curl python3 python3-pip python3-tkinter
}

install_python_313() {
    info "Installing Python 3.13..."
    if ! xbps-install -Sy python3.13 python3.13-pip python3.13-tkinter; then
        error "Python 3.13 install failed. Install manually and re-run."
    fi
}

find_python() {
    local candidates=(python3.13 python3.12 python3.11 python3.10 python3)
    local py version
    PYTHON_BIN=""
    for py in "${candidates[@]}"; do
        if command -v "$py" &>/dev/null; then
            version=$("$py" -c "import sys; print(f'{sys.version_info.major}{sys.version_info.minor:02d}')")
            if [[ "$version" -ge "$MIN_PY" ]]; then
                PYTHON_BIN="$py"
                info "Python OK: $($"$py" --version)"
                return 0
            fi
        fi
    done
    return 1
}

ensure_python() {
    if find_python; then
        return 0
    fi

    warn "Python 3.11+ not found."
    read -rp "Install Python 3.13 now? [y/N] " confirm
    [[ "${confirm,,}" != "y" ]] && error "Python 3.11+ required."

    install_python_313
    find_python || error "Python 3.11+ still not available."
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
install_system_deps
ensure_python

if [[ "$AUTO_YES" -eq 0 ]]; then
    read -rp "Install Password Generator to $INSTALL_DIR? [y/N] " confirm
    [[ "${confirm,,}" != "y" ]] && { echo "Aborted."; exit 0; }
fi

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT
fetch "$REPO_BASE/app.py" "$TEMP_DIR/app.py"
fetch "$REPO_BASE/password_generator.py" "$TEMP_DIR/password_generator.py"
fetch "$REPO_BASE/requirements.txt" "$TEMP_DIR/requirements.txt"
fetch "$REPO_BASE/password-generator.desktop" "$TEMP_DIR/password-generator.desktop"
fetch "$REPO_BASE/icon.png" "$TEMP_DIR/icon.png" || true

info "Copying files to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cp "$TEMP_DIR/app.py"                "$INSTALL_DIR/"
cp "$TEMP_DIR/password_generator.py" "$INSTALL_DIR/"
cp "$TEMP_DIR/requirements.txt"      "$INSTALL_DIR/"
[[ -f "$TEMP_DIR/icon.png" ]] && cp "$TEMP_DIR/icon.png" "$INSTALL_DIR/"

info "Fixing file permissions..."
chown -R "$TARGET_USER":"$TARGET_USER" "$INSTALL_DIR"

info "Creating virtual environment..."
sudo -u "$TARGET_USER" "$PYTHON_BIN" -m venv "$VENV_DIR"
[[ -x "$VENV_DIR/bin/python" ]] || error "Venv python not found at $VENV_DIR/bin/python"

info "Installing Python dependencies in venv..."
sudo -u "$TARGET_USER" "$VENV_DIR/bin/python" -m pip install --quiet -r "$INSTALL_DIR/requirements.txt"

info "Creating launcher at $BIN_LINK..."
cat > "$BIN_LINK" <<EOF
#!/usr/bin/env bash
exec "$VENV_DIR/bin/python" "$INSTALL_DIR/app.py" "\$@"
EOF
chmod +x "$BIN_LINK"

info "Installing desktop entry at $DESKTOP_FILE..."
write_desktop

if command -v update-desktop-database &>/dev/null; then
    update-desktop-database /usr/share/applications/ 2>/dev/null || true
fi

echo ""
info "Installation complete!"
info "Run with: $APP_NAME"
info "Or find it in your application menu as 'Password Generator'."
health_check
