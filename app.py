import customtkinter as ctk

from password_generator import (
    CharsetOptions,
    generate_password,
    parse_length,
    password_strength,
)

ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("green")

window = ctk.CTk()
window.minsize(width=480, height=620)
window.title("Password Generator")
window.resizable(False, False)

current_password = ""


def generate():
    global current_password

    options = CharsetOptions(
        uppercase=var_upper.get(),
        lowercase=var_lower.get(),
        digits=var_digits.get(),
        symbols=var_symbols.get(),
    )

    try:
        length = parse_length(length_entry.get())
        current_password = generate_password(length, options)
    except ValueError as exc:
        strength_var.set(str(exc))
        strength_display.configure(text_color="#F44336")
        _clear_display()
        copy_btn.configure(state="disabled")
        return

    password_display.configure(state="normal")
    password_display.delete(0, "end")
    password_display.insert(0, current_password)
    password_display.configure(state="readonly")

    label, color = password_strength(current_password)
    strength_var.set(f"Strength: {label}")
    strength_display.configure(text_color=color)
    copy_btn.configure(state="normal", text="Copy Password")


def copy_password():
    if not current_password:
        return
    window.clipboard_clear()
    window.clipboard_append(current_password)
    window.update()
    copy_btn.configure(text="Copied!", state="disabled")
    window.after(1500, lambda: copy_btn.configure(text="Copy Password", state="normal"))


def _clear_display():
    password_display.configure(state="normal")
    password_display.delete(0, "end")
    password_display.configure(state="readonly")


# ── UI ────────────────────────────────────────────────────────────────────────

SECTION_PAD = {"padx": 30, "pady": (0, 12)}

ctk.CTkLabel(
    window, text="Password Generator",
    font=ctk.CTkFont(size=22, weight="bold"),
).pack(pady=(32, 4))

ctk.CTkLabel(
    window, text="Secure passwords, instantly.",
    font=ctk.CTkFont(size=13), text_color="gray",
).pack(pady=(0, 24))

length_frame = ctk.CTkFrame(window, fg_color="transparent")
length_frame.pack(**SECTION_PAD)
ctk.CTkLabel(length_frame, text="Password length:", anchor="w").pack(side="left", padx=(0, 10))
length_entry = ctk.CTkEntry(
    length_frame, placeholder_text="12", width=80,
    border_color="#6ba10d", corner_radius=8,
)
length_entry.pack(side="left")

check_frame = ctk.CTkFrame(window, corner_radius=12)
check_frame.pack(padx=30, pady=(0, 16), fill="x")
ctk.CTkLabel(
    check_frame, text="Include:", anchor="w",
    font=ctk.CTkFont(weight="bold"),
).pack(anchor="w", padx=16, pady=(12, 6))

var_upper   = ctk.BooleanVar(value=True)
var_lower   = ctk.BooleanVar(value=True)
var_digits  = ctk.BooleanVar(value=True)
var_symbols = ctk.BooleanVar(value=True)

checkbox_row = ctk.CTkFrame(check_frame, fg_color="transparent")
checkbox_row.pack(padx=8, pady=(0, 12))
for label, var in [("A–Z", var_upper), ("a–z", var_lower), ("0–9", var_digits), ("!@#…", var_symbols)]:
    ctk.CTkCheckBox(
        checkbox_row, text=label, variable=var,
        corner_radius=6, fg_color="#6ba10d", hover_color="#44650a",
    ).pack(side="left", padx=10)

ctk.CTkButton(
    window, text="Generate Password",
    corner_radius=12, height=42,
    fg_color="#6ba10d", hover_color="#44650a",
    font=ctk.CTkFont(size=14, weight="bold"),
    command=generate,
).pack(padx=30, pady=(0, 20), fill="x")

password_display = ctk.CTkEntry(
    window, state="readonly", corner_radius=10,
    font=ctk.CTkFont(family="Courier", size=13),
    border_color="#6ba10d", height=42,
)
password_display.pack(padx=30, pady=(0, 10), fill="x")

strength_var = ctk.StringVar(value="")
strength_display = ctk.CTkLabel(
    window, textvariable=strength_var,
    font=ctk.CTkFont(size=12, weight="bold"),
)
strength_display.pack(pady=(0, 16))

copy_btn = ctk.CTkButton(
    window, text="Copy Password",
    corner_radius=12, height=42,
    fg_color="#6ba10d", hover_color="#44650a",
    font=ctk.CTkFont(size=14),
    state="disabled",
    command=copy_password,
)
copy_btn.pack(padx=30, pady=(0, 30), fill="x")

window.mainloop()
