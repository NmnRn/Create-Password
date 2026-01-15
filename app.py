import customtkinter as ctk
import string
import random
from tkinter import messagebox

symbols = "!@#$%&*_-+"
everything = list(string.ascii_letters + string.digits + symbols)

window = ctk.CTk()
window.minsize(width=450, height=600)
window.title("Create Password")
window.resizable(False, False)

def copy_entry(text, btn):
    window.clipboard_clear()
    window.clipboard_append(text)
    window.update()
    messagebox.showinfo(title="👍", message="Password Copied")
    btn.destroy()

def create_password():
    raw = entry.get().strip()
    if not raw:
        length = 8
    elif raw.isdigit():
        length = int(raw)
    else:
        length = 8

    if length > 8192:
        length = 8192

    execute(length)

def execute(length):
    main_button.configure(state="disabled")

    password = "".join(random.choice(everything) for _ in range(length))

    copy_button = ctk.CTkButton(
        master=window,
        text="Copy Password",
        corner_radius=32,
        fg_color="#6ba10d",
        hover_color="#44650a",
        command=lambda: copy_entry(password, copy_button)
    )
    copy_button.place(relx=0.5, rely=0.4, anchor="center")

    main_button.configure(state="normal")

entry = ctk.CTkEntry(
    master=window,
    placeholder_text="Length of password",
    border_color="#c77e0a",
    corner_radius=32,
    width=200
)
entry.place(rely=0.15, relx=0.5, anchor="center")

main_button = ctk.CTkButton(
    master=window,
    text="Create Password",
    corner_radius=16,
    command=create_password,
    fg_color="#6ba10d",
    hover_color="#44650a"
)
main_button.place(rely=0.30, relx=0.5, anchor="center")

window.mainloop()
