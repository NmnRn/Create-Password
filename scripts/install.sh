#!/usr/bin/env bash
# install.sh — Install Password Generator
# Supports: Debian/Ubuntu, Fedora/RHEL/CentOS, Arch Linux, openSUSE

set -euo pipefail

APP_NAME="password-generator"
INSTALL_DIR="/opt/$APP_NAME"
VENV_DIR="$INSTALL_DIR/venv"
PYTHON_BIN="python3.13"
BIN_LINK="/usr/local/bin/$APP_NAME"
DESKTOP_FILE="/usr/share/applications/$APP_NAME.desktop"
AUTO_YES=0
SCRIPT_PATH="${BASH_SOURCE[0]-}"
if [[ -n "$SCRIPT_PATH" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
else
    SCRIPT_DIR="$PWD"
fi
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TEMP_DIR=""

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }
require_cmd() { command -v "$1" &>/dev/null || error "Missing command: $1"; }
fetch() {
    local url="$1" dest="$2"
    curl -fSL --retry 3 --retry-delay 1 "$url" -o "$dest"
}
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

# ── Root check ────────────────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] && error "Run as root: sudo bash scripts/install.sh"

# ── Python version check ──────────────────────────────────────────────────────
check_python() {
    local py
    py=$(command -v "$PYTHON_BIN" 2>/dev/null || true)
    [[ -z "$py" ]] && error "Python 3.13 not found. Install Python 3.13+ first."

    local version
    version=$("$py" -c "import sys; print(f'{sys.version_info.major}{sys.version_info.minor:02d}')")
    [[ "$version" -lt 313 ]] && error "Python 3.13+ required (found $($"$py" --version))."
    info "Python OK: $($"$py" --version)"
}

# ── Distro detection ──────────────────────────────────────────────────────────
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "${ID:-unknown}"
    else
        echo "unknown"
    fi
}

install_system_deps() {
    local distro
    distro=$(detect_distro)
    info "Detected distro: $distro"

    case "$distro" in
        ubuntu|debian|linuxmint|pop|elementary|kali|raspbian)
            info "Installing system dependencies via apt..."
            apt-get update -qq
            apt-get install -y python3-tk python3-pip
            ;;
        fedora)
            info "Installing system dependencies via dnf..."
            dnf install -y python3-tkinter python3-pip
            ;;
        rhel|centos|almalinux|rocky)
            info "Installing system dependencies via dnf/yum..."
            if command -v dnf &>/dev/null; then
                dnf install -y python3-tkinter python3-pip
            else
                yum install -y python3-tkinter python3-pip
            fi
            ;;
        arch|manjaro|endeavouros|garuda)
            info "Installing system dependencies via pacman..."
            pacman -Sy --noconfirm python-tkinter python-pip
            ;;
        opensuse*|sles)
            info "Installing system dependencies via zypper..."
            zypper install -y python3-tk python3-pip
            ;;
        void)
            info "Installing system dependencies via xbps-install..."
            xbps-install -Sy python3-tkinter python3-pip
            ;;
        *)
            warn "Unknown distro '$distro'. Skipping system package install."
            warn "Make sure python3-tkinter and python3-pip are installed manually."
            ;;
    esac
}

# ── Install ───────────────────────────────────────────────────────────────────
check_python
install_system_deps

if [[ "$AUTO_YES" -eq 0 ]]; then
    read -rp "Install Password Generator to $INSTALL_DIR? [y/N] " confirm
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

info "Copying files to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cp "$PROJECT_DIR/app.py"                "$INSTALL_DIR/"
cp "$PROJECT_DIR/password_generator.py" "$INSTALL_DIR/"
cp "$PROJECT_DIR/requirements.txt"      "$INSTALL_DIR/"
[[ -f "$PROJECT_DIR/icon.png" ]] && cp "$PROJECT_DIR/icon.png" "$INSTALL_DIR/"

info "Creating virtual environment..."
"$PYTHON_BIN" -m venv "$VENV_DIR"

if [[ ! -x "$VENV_DIR/bin/python" ]]; then
    error "Venv python not found at $VENV_DIR/bin/python"
fi

info "Installing Python dependencies in venv..."
"$VENV_DIR/bin/python" -m pip install --quiet -r "$INSTALL_DIR/requirements.txt"

info "Creating launcher at $BIN_LINK..."
cat > "$BIN_LINK" <<EOF
#!/usr/bin/env bash
exec "$VENV_DIR/bin/python" "$INSTALL_DIR/app.py" "\$@"
EOF
chmod +x "$BIN_LINK"

info "Installing desktop entry at $DESKTOP_FILE..."
DESKTOP_SRC="$PROJECT_DIR/password-generator.desktop"
[[ ! -f "$DESKTOP_SRC" ]] && error "Desktop file not found: $DESKTOP_SRC"
cp "$DESKTOP_SRC" "$DESKTOP_FILE"

if command -v update-desktop-database &>/dev/null; then
    update-desktop-database /usr/share/applications/ 2>/dev/null || true
fi

echo ""
info "Installation complete!"
info "Run with: $APP_NAME"
info "Or find it in your application menu as 'Password Generator'."
health_check
