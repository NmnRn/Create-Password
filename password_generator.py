"""Core password generation logic — no GUI dependencies."""

import secrets
import string
from dataclasses import dataclass

SYMBOLS = "!@#$%&*_-+"

MIN_LENGTH = 4
MAX_LENGTH = 8192


@dataclass(frozen=True)
class CharsetOptions:
    uppercase: bool = True
    lowercase: bool = True
    digits: bool = True
    symbols: bool = True


def build_charset(options: CharsetOptions) -> str:
    charset = ""
    if options.uppercase:
        charset += string.ascii_uppercase
    if options.lowercase:
        charset += string.ascii_lowercase
    if options.digits:
        charset += string.digits
    if options.symbols:
        charset += SYMBOLS
    return charset


def generate_password(length: int, options: CharsetOptions) -> str:
    if length < MIN_LENGTH:
        raise ValueError(f"Length must be at least {MIN_LENGTH}")
    if length > MAX_LENGTH:
        raise ValueError(f"Length must be at most {MAX_LENGTH}")

    charset = build_charset(options)
    if not charset:
        raise ValueError("At least one character type must be selected")

    return "".join(secrets.choice(charset) for _ in range(length))


def password_strength(password: str) -> tuple[str, str]:
    """Return (label, hex_color) for the given password."""
    length = len(password)
    variety = sum([
        any(c.isupper() for c in password),
        any(c.islower() for c in password),
        any(c.isdigit() for c in password),
        any(c in SYMBOLS for c in password),
    ])

    if length >= 16 and variety == 4:
        return "Very Strong", "#4CAF50"
    if length >= 12 and variety >= 3:
        return "Strong", "#8BC34A"
    if length >= 8 and variety >= 2:
        return "Medium", "#FFC107"
    return "Weak", "#F44336"


def parse_length(raw: str, default: int = 12) -> int:
    """Parse user-supplied length string, clamp to valid range."""
    try:
        length = int(raw.strip()) if raw.strip() else default
    except ValueError:
        length = default
    return max(MIN_LENGTH, min(length, MAX_LENGTH))
