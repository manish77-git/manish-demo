"""
FileWatch — Settings Panel

Application settings: ignored folders, monitoring preferences,
history management, and CSV export.
"""

from pathlib import Path
from tkinter import filedialog

import customtkinter as ctk

from ui.components import (
    COLORS, FONTS,
    Card, SectionLabel, ConfirmDialog, ToastNotification,
)


class SettingsPanel(ctk.CTkFrame):
    """Settings panel for FileWatch configuration."""

    def __init__(self, master, app_controller):
        super().__init__(master, fg_color=COLORS["bg_primary"])
        self.app = app_controller
        self._build_ui()

    def _build_ui(self):
        """Build the settings panel layout."""
        scroll = ctk.CTkScrollableFrame(
            self,
            fg_color=COLORS["bg_primary"],
            scrollbar_button_color=COLORS["border"],
            scrollbar_button_hover_color=COLORS["border_hover"],
        )
        scroll.pack(fill="both", expand=True, padx=0, pady=0)

        # Header
        ctk.CTkLabel(
            scroll,
            text="SETTINGS",
            font=FONTS["heading"],
            text_color=COLORS["text_primary"],
        ).pack(anchor="w", padx=20, pady=(20, 16))

        # ── APPLICATION INFO ──
        SectionLabel(scroll, text="Application").pack(anchor="w", padx=20, pady=(0, 8))

        info_card = Card(scroll)
        info_card.pack(fill="x", padx=20, pady=(0, 16))

        ctk.CTkLabel(
            info_card,
            text="🔐  FileWatch",
            font=FONTS["title"],
            text_color=COLORS["text_primary"],
        ).pack(anchor="w", padx=16, pady=(16, 4))

        ctk.CTkLabel(
            info_card,
            text="Local File Integrity Monitoring",
            font=FONTS["subtitle"],
            text_color=COLORS["text_secondary"],
        ).pack(anchor="w", padx=16, pady=(0, 4))

        ctk.CTkLabel(
            info_card,
            text="SHA-256 is a cryptographic hash function used here as a file fingerprint.\n"
                 "If file contents change, the resulting hash will normally change.\n\n"
                 "This tool detects file changes — it is not antivirus software.",
            font=FONTS["body_small"],
            text_color=COLORS["text_muted"],
            anchor="w",
            justify="left",
        ).pack(anchor="w", padx=16, pady=(0, 16))

        # ── MONITORING SETTINGS ──
        SectionLabel(scroll, text="Monitoring").pack(anchor="w", padx=20, pady=(0, 8))

        monitor_card = Card(scroll)
        monitor_card.pack(fill="x", padx=20, pady=(0, 16))

        # Auto-monitor checkbox
        self._auto_monitor_var = ctk.BooleanVar(value=self.app.config.auto_monitor)
        auto_cb = ctk.CTkCheckBox(
            monitor_card,
            text="Start monitoring after baseline creation",
            font=FONTS["body"],
            text_color=COLORS["text_primary"],
            fg_color=COLORS["accent"],
            hover_color=COLORS["accent_hover"],
            border_color=COLORS["border"],
            checkmark_color="#ffffff",
            corner_radius=4,
            variable=self._auto_monitor_var,
            command=self._on_auto_monitor_change,
        )
        auto_cb.pack(anchor="w", padx=16, pady=(16, 8))

        # Recursive checkbox
        self._recursive_var = ctk.BooleanVar(value=self.app.config.recursive)
        recursive_cb = ctk.CTkCheckBox(
            monitor_card,
            text="Recursive monitoring (include subfolders)",
            font=FONTS["body"],
            text_color=COLORS["text_primary"],
            fg_color=COLORS["accent"],
            hover_color=COLORS["accent_hover"],
            border_color=COLORS["border"],
            checkmark_color="#ffffff",
            corner_radius=4,
            variable=self._recursive_var,
            command=self._on_recursive_change,
        )
        recursive_cb.pack(anchor="w", padx=16, pady=(0, 16))

        # ── IGNORED FOLDERS ──
        SectionLabel(scroll, text="Ignored Folders").pack(anchor="w", padx=20, pady=(0, 8))

        ignored_card = Card(scroll)
        ignored_card.pack(fill="x", padx=20, pady=(0, 16))

        ctk.CTkLabel(
            ignored_card,
            text="Folders matching these names will be skipped during scanning.\n"
                 "Changes inside ignored folders will not be detected.",
            font=FONTS["body_small"],
            text_color=COLORS["text_secondary"],
            anchor="w",
            justify="left",
        ).pack(anchor="w", padx=16, pady=(12, 8))

        # Ignored folders list
        self._ignored_frame = ctk.CTkFrame(ignored_card, fg_color="transparent")
        self._ignored_frame.pack(fill="x", padx=16, pady=(0, 8))

        self._rebuild_ignored_list()

        # Add folder entry
        add_frame = ctk.CTkFrame(ignored_card, fg_color="transparent")
        add_frame.pack(fill="x", padx=16, pady=(0, 16))

        self._add_entry = ctk.CTkEntry(
            add_frame,
            placeholder_text="Add folder name...",
            font=FONTS["body"],
            fg_color=COLORS["bg_input"],
            border_color=COLORS["border"],
            text_color=COLORS["text_primary"],
            placeholder_text_color=COLORS["text_muted"],
            corner_radius=8,
            width=200,
        )
        self._add_entry.pack(side="left", padx=(0, 8))
        self._add_entry.bind("<Return>", lambda e: self._on_add_ignored())

        add_btn = ctk.CTkButton(
            add_frame,
            text="+ Add",
            font=FONTS["body"],
            fg_color=COLORS["accent"],
            hover_color=COLORS["accent_hover"],
            corner_radius=8,
            width=80,
            command=self._on_add_ignored,
        )
        add_btn.pack(side="left")

        # ── DATABASE ──
        SectionLabel(scroll, text="Database").pack(anchor="w", padx=20, pady=(0, 8))

        db_card = Card(scroll)
        db_card.pack(fill="x", padx=20, pady=(0, 16))

        db_btn_frame = ctk.CTkFrame(db_card, fg_color="transparent")
        db_btn_frame.pack(fill="x", padx=16, pady=16)

        clear_btn = ctk.CTkButton(
            db_btn_frame,
            text="🗑️  Clear History",
            font=FONTS["button"],
            fg_color=COLORS["red_dim"],
            hover_color=COLORS["red"],
            text_color=COLORS["red"],
            corner_radius=8,
            width=160,
            command=self._on_clear_history,
        )
        clear_btn.pack(side="left", padx=(0, 12))

        export_btn = ctk.CTkButton(
            db_btn_frame,
            text="📄  Export History (CSV)",
            font=FONTS["button"],
            fg_color=COLORS["bg_tertiary"],
            hover_color=COLORS["border_hover"],
            text_color=COLORS["text_primary"],
            corner_radius=8,
            width=180,
            command=self._on_export_csv,
        )
        export_btn.pack(side="left")

    # ──────────────────────────────────────────────────────────────────
    # HANDLERS
    # ──────────────────────────────────────────────────────────────────

    def _on_auto_monitor_change(self):
        self.app.config.auto_monitor = self._auto_monitor_var.get()

    def _on_recursive_change(self):
        self.app.config.recursive = self._recursive_var.get()

    def _rebuild_ignored_list(self):
        """Rebuild the ignored folders tag list."""
        for widget in self._ignored_frame.winfo_children():
            widget.destroy()

        for folder in self.app.config.ignored_folders:
            tag = ctk.CTkFrame(
                self._ignored_frame,
                fg_color=COLORS["bg_tertiary"],
                corner_radius=6,
            )
            tag.pack(side="left", padx=(0, 6), pady=4)

            ctk.CTkLabel(
                tag,
                text=f"  {folder}  ",
                font=FONTS["body_small"],
                text_color=COLORS["text_primary"],
            ).pack(side="left", padx=(8, 0), pady=4)

            remove_btn = ctk.CTkButton(
                tag,
                text="✕",
                font=("Segoe UI", 10),
                fg_color="transparent",
                hover_color=COLORS["red_dim"],
                text_color=COLORS["text_secondary"],
                width=24,
                height=24,
                corner_radius=4,
                command=lambda f=folder: self._on_remove_ignored(f),
            )
            remove_btn.pack(side="left", padx=(0, 4), pady=2)

    def _on_add_ignored(self):
        """Add a new folder to the ignored list."""
        name = self._add_entry.get().strip()
        if not name:
            return

        folders = self.app.config.ignored_folders
        if name not in folders:
            folders.append(name)
            self.app.config.ignored_folders = folders
            self._rebuild_ignored_list()

        self._add_entry.delete(0, "end")

    def _on_remove_ignored(self, folder: str):
        """Remove a folder from the ignored list."""
        folders = self.app.config.ignored_folders
        if folder in folders:
            folders.remove(folder)
            self.app.config.ignored_folders = folders
            self._rebuild_ignored_list()

    def _on_clear_history(self):
        """Clear all change history with confirmation."""
        ConfirmDialog(
            self,
            title="Clear History?",
            message="This will permanently delete all change event history.\n\nBaselines will not be affected.",
            confirm_text="Clear",
            cancel_text="Cancel",
            on_confirm=self._do_clear_history,
        )

    def _do_clear_history(self):
        self.app.db.clear_history()
        self._show_toast("✅ History cleared", "success")

    def _on_export_csv(self):
        """Export history to CSV."""
        filepath = filedialog.asksaveasfilename(
            title="Export History as CSV",
            defaultextension=".csv",
            filetypes=[("CSV Files", "*.csv"), ("All Files", "*.*")],
            initialfile="filewatch_history.csv",
        )
        if not filepath:
            return

        try:
            self.app.db.export_to_csv(filepath)
            self._show_toast(f"✅ History exported to {Path(filepath).name}", "success")
        except Exception as e:
            self._show_toast(f"⚠️ Export failed: {e}", "error")

    def _show_toast(self, message: str, toast_type: str = "info"):
        toast = ToastNotification(self, message=message, toast_type=toast_type)
        toast.place(relx=0.5, rely=0.95, anchor="s")
