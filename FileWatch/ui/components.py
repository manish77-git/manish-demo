"""
FileWatch — Reusable UI Components

Dark theme design system and reusable CustomTkinter widgets.
"""

import customtkinter as ctk
from typing import Callable

# ──────────────────────────────────────────────────────────────────────
# COLOR PALETTE — Professional dark security-utility theme
# ──────────────────────────────────────────────────────────────────────

COLORS = {
    # Backgrounds
    "bg_primary": "#0f1117",       # Main window background
    "bg_secondary": "#161b22",     # Card backgrounds
    "bg_tertiary": "#1c2333",      # Slightly lighter cards / hover
    "bg_input": "#21273a",         # Input fields

    # Borders
    "border": "#2a3040",           # Subtle card borders
    "border_hover": "#3a4560",     # Hover state borders

    # Text
    "text_primary": "#e6edf3",     # Primary text
    "text_secondary": "#8b949e",   # Secondary / muted text
    "text_muted": "#484f58",       # Very muted text

    # Accent — cool teal/cyan for a security feel
    "accent": "#2ea8a0",
    "accent_hover": "#38c4bb",
    "accent_dim": "#1a6b66",

    # Status colors
    "green": "#3fb950",            # Active / success / unchanged
    "green_dim": "#1a3a2a",
    "yellow": "#d29922",           # Warning / attention
    "yellow_dim": "#3a2f1a",
    "red": "#f85149",              # Error / stopped / deleted
    "red_dim": "#3a1a1a",
    "blue": "#58a6ff",             # Info / added
    "blue_dim": "#1a2a3a",
    "purple": "#bc8cff",           # Renamed
    "purple_dim": "#2a1a3a",

    # Event type specific
    "added": "#58a6ff",
    "modified": "#d29922",
    "deleted": "#f85149",
    "renamed": "#bc8cff",
    "unchanged": "#3fb950",
}

# Font configuration
FONTS = {
    "title": ("Segoe UI", 20, "bold"),
    "subtitle": ("Segoe UI", 12),
    "heading": ("Segoe UI Semibold", 14),
    "body": ("Segoe UI", 13),
    "body_small": ("Segoe UI", 11),
    "mono": ("Cascadia Code", 12),
    "mono_small": ("Cascadia Code", 10),
    "stat_value": ("Segoe UI", 28, "bold"),
    "stat_label": ("Segoe UI", 11),
    "button": ("Segoe UI Semibold", 13),
}

# Event type display config
EVENT_CONFIG = {
    "ADDED": {"icon": "➕", "color": COLORS["added"], "bg": COLORS["blue_dim"], "label": "Added"},
    "MODIFIED": {"icon": "✏️", "color": COLORS["modified"], "bg": COLORS["yellow_dim"], "label": "Modified"},
    "DELETED": {"icon": "🗑️", "color": COLORS["deleted"], "bg": COLORS["red_dim"], "label": "Deleted"},
    "RENAMED": {"icon": "↪️", "color": COLORS["renamed"], "bg": COLORS["purple_dim"], "label": "Renamed"},
}


# ──────────────────────────────────────────────────────────────────────
# REUSABLE WIDGETS
# ──────────────────────────────────────────────────────────────────────


class Card(ctk.CTkFrame):
    """A styled card container with subtle border and rounded corners."""

    def __init__(self, master, **kwargs):
        super().__init__(
            master,
            fg_color=COLORS["bg_secondary"],
            corner_radius=12,
            border_width=1,
            border_color=COLORS["border"],
            **kwargs,
        )


class SectionLabel(ctk.CTkLabel):
    """A section heading label."""

    def __init__(self, master, text: str, **kwargs):
        super().__init__(
            master,
            text=text.upper(),
            font=("Segoe UI", 11, "bold"),
            text_color=COLORS["text_secondary"],
            anchor="w",
            **kwargs,
        )


class StatCard(Card):
    """A stat display card with a large number and label."""

    def __init__(self, master, label: str, value: str = "0", **kwargs):
        super().__init__(master, **kwargs)

        self._value_label = ctk.CTkLabel(
            self,
            text=value,
            font=FONTS["stat_value"],
            text_color=COLORS["text_primary"],
        )
        self._value_label.pack(padx=16, pady=(16, 2))

        self._label = ctk.CTkLabel(
            self,
            text=label,
            font=FONTS["stat_label"],
            text_color=COLORS["text_secondary"],
        )
        self._label.pack(padx=16, pady=(0, 16))

    def set_value(self, value: str):
        self._value_label.configure(text=value)


class StatusBadge(ctk.CTkFrame):
    """A small status indicator badge with icon + text."""

    def __init__(self, master, text: str = "Inactive", status: str = "inactive", **kwargs):
        super().__init__(master, fg_color="transparent", **kwargs)

        self._dot_colors = {
            "active": COLORS["green"],
            "warning": COLORS["yellow"],
            "stopped": COLORS["red"],
            "inactive": COLORS["text_muted"],
        }

        self._dot = ctk.CTkLabel(
            self,
            text="●",
            font=("Segoe UI", 14),
            text_color=self._dot_colors.get(status, COLORS["text_muted"]),
            width=20,
        )
        self._dot.pack(side="left", padx=(0, 4))

        self._text = ctk.CTkLabel(
            self,
            text=text,
            font=FONTS["body"],
            text_color=COLORS["text_primary"],
        )
        self._text.pack(side="left")

    def set_status(self, text: str, status: str):
        dot_colors = {
            "active": COLORS["green"],
            "warning": COLORS["yellow"],
            "stopped": COLORS["red"],
            "inactive": COLORS["text_muted"],
        }
        self._dot.configure(text_color=dot_colors.get(status, COLORS["text_muted"]))
        self._text.configure(text=text)


class ChangeEntry(ctk.CTkFrame):
    """A single change event row for display in a list."""

    def __init__(self, master, event_type: str, file_path: str,
                 timestamp: str = "", on_click: Callable | None = None, **kwargs):
        super().__init__(
            master,
            fg_color=COLORS["bg_tertiary"],
            corner_radius=8,
            height=44,
            **kwargs,
        )
        self.pack_propagate(False)

        config = EVENT_CONFIG.get(event_type, EVENT_CONFIG["MODIFIED"])

        # Left color strip
        strip = ctk.CTkFrame(self, fg_color=config["color"], width=4, corner_radius=2)
        strip.pack(side="left", fill="y", padx=(0, 0), pady=4)

        # Icon + filename
        icon_label = ctk.CTkLabel(
            self,
            text=f"  {config['icon']}",
            font=("Segoe UI", 13),
            text_color=config["color"],
            width=36,
        )
        icon_label.pack(side="left", padx=(4, 0))

        # Filename (just the basename for cleanliness, full path on click)
        from pathlib import Path as P
        display_name = P(file_path).name
        name_label = ctk.CTkLabel(
            self,
            text=display_name,
            font=FONTS["body"],
            text_color=COLORS["text_primary"],
            anchor="w",
        )
        name_label.pack(side="left", padx=(4, 8), fill="x", expand=True)

        # Event type label
        type_label = ctk.CTkLabel(
            self,
            text=config["label"],
            font=FONTS["body_small"],
            text_color=config["color"],
            width=70,
        )
        type_label.pack(side="right", padx=(4, 8))

        # Timestamp
        if timestamp:
            time_label = ctk.CTkLabel(
                self,
                text=timestamp,
                font=FONTS["body_small"],
                text_color=COLORS["text_secondary"],
                width=50,
            )
            time_label.pack(side="right", padx=(4, 4))

        # Click binding
        if on_click:
            for widget in [self, icon_label, name_label, type_label]:
                widget.bind("<Button-1>", lambda e: on_click())
                widget.configure(cursor="hand2")


class ToastNotification(ctk.CTkFrame):
    """A temporary toast notification that auto-dismisses."""

    def __init__(self, master, message: str, toast_type: str = "info",
                 duration_ms: int = 3000):
        colors = {
            "info": (COLORS["blue"], COLORS["blue_dim"]),
            "success": (COLORS["green"], COLORS["green_dim"]),
            "warning": (COLORS["yellow"], COLORS["yellow_dim"]),
            "error": (COLORS["red"], COLORS["red_dim"]),
        }
        fg, bg = colors.get(toast_type, colors["info"])

        super().__init__(
            master,
            fg_color=bg,
            corner_radius=8,
            border_width=1,
            border_color=fg,
        )

        label = ctk.CTkLabel(
            self,
            text=message,
            font=FONTS["body"],
            text_color=fg,
        )
        label.pack(padx=16, pady=10)

        # Auto-dismiss
        self.after(duration_ms, self.destroy)


class ConfirmDialog(ctk.CTkToplevel):
    """A modal confirmation dialog."""

    def __init__(self, master, title: str, message: str,
                 confirm_text: str = "Confirm",
                 cancel_text: str = "Cancel",
                 on_confirm: Callable | None = None):
        super().__init__(master)

        self.title(title)
        self.geometry("420x220")
        self.resizable(False, False)
        self.configure(fg_color=COLORS["bg_primary"])

        # Center on parent
        self.transient(master)
        self.grab_set()

        # Warning icon + message
        icon_label = ctk.CTkLabel(
            self,
            text="⚠️",
            font=("Segoe UI", 32),
        )
        icon_label.pack(pady=(24, 8))

        msg_label = ctk.CTkLabel(
            self,
            text=message,
            font=FONTS["body"],
            text_color=COLORS["text_primary"],
            wraplength=360,
        )
        msg_label.pack(padx=24, pady=(0, 24))

        # Buttons
        btn_frame = ctk.CTkFrame(self, fg_color="transparent")
        btn_frame.pack(fill="x", padx=24, pady=(0, 20))

        cancel_btn = ctk.CTkButton(
            btn_frame,
            text=cancel_text,
            font=FONTS["button"],
            fg_color=COLORS["bg_tertiary"],
            hover_color=COLORS["border_hover"],
            text_color=COLORS["text_primary"],
            corner_radius=8,
            width=120,
            command=self.destroy,
        )
        cancel_btn.pack(side="left", expand=True, padx=8)

        confirm_btn = ctk.CTkButton(
            btn_frame,
            text=confirm_text,
            font=FONTS["button"],
            fg_color=COLORS["red"],
            hover_color="#d43d36",
            text_color="#ffffff",
            corner_radius=8,
            width=120,
            command=lambda: (on_confirm() if on_confirm else None, self.destroy()),
        )
        confirm_btn.pack(side="right", expand=True, padx=8)

        # Focus
        self.after(100, self.focus_force)
