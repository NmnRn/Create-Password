#!/usr/bin/env bash
# install.sh — Install Password Generator
# Supports: Debian/Ubuntu, Fedora/RHEL/CentOS, Arch Linux, openSUSE

set -euo pipefail

APP_NAME="password-generator"
INSTALL_DIR="/opt/$APP_NAME"
BIN_LINK="/usr/local/bin/$APP_NAME"
DESKTOP_FILE="/usr/share/applications/$APP_NAME.desktop"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Root check ────────────────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] && error "Run as root: sudo bash scripts/install.sh"

# ── Python version check ──────────────────────────────────────────────────────
check_python() {
    local py
    py=$(command -v python3 2>/dev/null || true)
    [[ -z "$py" ]] && error "Python 3 not found. Install Python 3.10+ first."

    local version
    version=$("$py" -c "import sys; print(f'{sys.version_info.major}{sys.version_info.minor:02d}')")
    [[ "$version" -lt 310 ]] && error "Python 3.10+ required (found $("$py" --version))."
    info "Python OK: $("$py" --version)"
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

info "Copying files to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cp "$PROJECT_DIR/app.py"                "$INSTALL_DIR/"
cp "$PROJECT_DIR/password_generator.py" "$INSTALL_DIR/"
cp "$PROJECT_DIR/requirements.txt"      "$INSTALL_DIR/"
[[ -f "$PROJECT_DIR/icon.png" ]] && cp "$PROJECT_DIR/icon.png" "$INSTALL_DIR/"

info "Installing Python dependencies..."
python3 -m pip install --quiet -r "$INSTALL_DIR/requirements.txt"

info "Creating launcher at $BIN_LINK..."
cat > "$BIN_LINK" <<EOF
#!/usr/bin/env bash
exec python3 "$INSTALL_DIR/app.py" "\$@"
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
