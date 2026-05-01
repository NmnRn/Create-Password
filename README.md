# Password Generator

A simple, secure password generator desktop app built with Python and CustomTkinter.

![Python](https://img.shields.io/badge/Python-3.11%2B-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- Cryptographically secure password generation (`secrets` module)
- Custom password length (4–8192 characters)
- Character type selection: uppercase, lowercase, digits, symbols
- Password strength indicator (Weak / Medium / Strong / Very Strong)
- One-click copy to clipboard
- Clean dark-mode UI

## Requirements

- Python 3.11+
- customtkinter >= 5.2.0

## Installation

### Install (Linux — distro-specific)

#### Debian/Ubuntu

```bash
curl -fsSL https://raw.githubusercontent.com/NmnRn/Create-Password/main/scripts/debian/install.sh | sudo bash
```

#### Arch/Manjaro

```bash
curl -fsSL https://raw.githubusercontent.com/NmnRn/Create-Password/main/scripts/arch/install.sh | sudo bash
```

#### Fedora/RHEL

```bash
curl -fsSL https://raw.githubusercontent.com/NmnRn/Create-Password/main/scripts/fedora/install.sh | sudo bash
```

#### openSUSE/SLES

```bash
curl -fsSL https://raw.githubusercontent.com/NmnRn/Create-Password/main/scripts/opensuse/install.sh | sudo bash
```

#### Void Linux

```bash
curl -fsSL https://raw.githubusercontent.com/NmnRn/Create-Password/main/scripts/void/install.sh | sudo bash
```

Installs to `/home/$USER/password-generator`, creates a launcher at `/usr/local/bin/password-generator` and adds a desktop entry.

### Upgrade

```bash
sudo bash scripts/<distro>/upgrade.sh
```

### Uninstall

```bash
sudo bash scripts/<distro>/uninstall.sh
```

### Manual install

```bash
pip install -r requirements.txt
python3 app.py
```

### Run tests

```bash
python3 -m pytest tests/ -v
```

## License

MIT. See [LICENSE](LICENSE).
