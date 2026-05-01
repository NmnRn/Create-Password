# Password Generator

A simple, secure password generator desktop app built with Python and CustomTkinter.

![Python](https://img.shields.io/badge/Python-3.10%2B-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- Cryptographically secure password generation (`secrets` module)
- Custom password length (4–8192 characters)
- Character type selection: uppercase, lowercase, digits, symbols
- Password strength indicator (Weak / Medium / Strong / Very Strong)
- One-click copy to clipboard
- Clean dark-mode UI

## Requirements

- Python 3.10+
- customtkinter >= 5.2.0

## Installation

### Quick install (Linux — all distros)

```bash
curl -fsSL https://raw.githubusercontent.com/NmnRn/Create-Password/main/scripts/install.sh | sudo bash
```

Or clone and install manually:

```bash
git clone https://github.com/NmnRn/Create-Password.git
cd Create-Password
sudo bash scripts/install.sh
```

Installs to `/opt/password-generator`, creates a launcher at `/usr/local/bin/password-generator` and adds a desktop entry. Supports Debian/Ubuntu, Fedora/RHEL/CentOS, Arch Linux, openSUSE, and Void Linux.

### Upgrade

```bash
sudo bash scripts/upgrade.sh
```

### Uninstall

```bash
sudo bash scripts/uninstall.sh
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

MIT
