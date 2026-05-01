import string
import pytest

from password_generator import (
    SYMBOLS,
    MIN_LENGTH,
    MAX_LENGTH,
    CharsetOptions,
    build_charset,
    generate_password,
    password_strength,
    parse_length,
)


# ── build_charset ─────────────────────────────────────────────────────────────

class TestBuildCharset:
    def test_all_enabled(self):
        charset = build_charset(CharsetOptions())
        assert all(c in charset for c in string.ascii_uppercase)
        assert all(c in charset for c in string.ascii_lowercase)
        assert all(c in charset for c in string.digits)
        assert all(c in charset for c in SYMBOLS)

    def test_only_digits(self):
        opts = CharsetOptions(uppercase=False, lowercase=False, digits=True, symbols=False)
        assert build_charset(opts) == string.digits

    def test_only_symbols(self):
        opts = CharsetOptions(uppercase=False, lowercase=False, digits=False, symbols=True)
        assert build_charset(opts) == SYMBOLS

    def test_all_disabled_returns_empty(self):
        opts = CharsetOptions(uppercase=False, lowercase=False, digits=False, symbols=False)
        assert build_charset(opts) == ""


# ── generate_password ─────────────────────────────────────────────────────────

class TestGeneratePassword:
    def test_returns_correct_length(self):
        pw = generate_password(16, CharsetOptions())
        assert len(pw) == 16

    def test_minimum_length(self):
        pw = generate_password(MIN_LENGTH, CharsetOptions())
        assert len(pw) == MIN_LENGTH

    def test_maximum_length(self):
        pw = generate_password(MAX_LENGTH, CharsetOptions())
        assert len(pw) == MAX_LENGTH

    def test_too_short_raises(self):
        with pytest.raises(ValueError):
            generate_password(MIN_LENGTH - 1, CharsetOptions())

    def test_too_long_raises(self):
        with pytest.raises(ValueError):
            generate_password(MAX_LENGTH + 1, CharsetOptions())

    def test_empty_charset_raises(self):
        opts = CharsetOptions(uppercase=False, lowercase=False, digits=False, symbols=False)
        with pytest.raises(ValueError):
            generate_password(8, opts)

    def test_only_digits_option(self):
        opts = CharsetOptions(uppercase=False, lowercase=False, digits=True, symbols=False)
        pw = generate_password(20, opts)
        assert all(c in string.digits for c in pw)

    def test_only_uppercase_option(self):
        opts = CharsetOptions(uppercase=True, lowercase=False, digits=False, symbols=False)
        pw = generate_password(20, opts)
        assert all(c in string.ascii_uppercase for c in pw)

    def test_passwords_are_not_identical(self):
        opts = CharsetOptions()
        passwords = {generate_password(32, opts) for _ in range(10)}
        assert len(passwords) > 1


# ── password_strength ─────────────────────────────────────────────────────────

class TestPasswordStrength:
    def test_very_strong(self):
        label, _ = password_strength("Aa1!" * 5)  # 20 chars, 4 types
        assert label == "Very Strong"

    def test_strong(self):
        label, _ = password_strength("Aa1" * 4)   # 12 chars, 3 types
        assert label == "Strong"

    def test_medium(self):
        label, _ = password_strength("Aa" * 4)    # 8 chars, 2 types
        assert label == "Medium"

    def test_weak_short_single_type(self):
        label, _ = password_strength("aaaa")
        assert label == "Weak"

    def test_returns_hex_color(self):
        _, color = password_strength("Aa1!" * 5)
        assert color.startswith("#")
        assert len(color) == 7


# ── parse_length ──────────────────────────────────────────────────────────────

class TestParseLength:
    def test_valid_number(self):
        assert parse_length("20") == 20

    def test_empty_string_returns_default(self):
        assert parse_length("", default=12) == 12

    def test_whitespace_returns_default(self):
        assert parse_length("   ", default=12) == 12

    def test_non_numeric_returns_default(self):
        assert parse_length("abc", default=12) == 12

    def test_clamps_below_minimum(self):
        assert parse_length("1") == MIN_LENGTH

    def test_clamps_above_maximum(self):
        assert parse_length("99999") == MAX_LENGTH
