"""
FileWatch — History Panel

Displays change event history with filtering, search, and detail view.
"""

from datetime import datetime
from pathlib import Path
from typing import Callable

import customtkinter as ctk

from ui.components import (
    COLORS, FONTS, EVENT_CONFIG,
    Card, SectionLabel, ChangeEntry,
)
from utils.file_utils import format_size, format_timestamp, format_time_short


class HistoryPanel(ctk.CTkFrame):
    """Change history panel with filtering and search."""

    def __init__(self, master, app_controller):
        super().__init__(master, fg_color=COLORS["bg_primary"])
        self.app = app_controller
        self._current_filter = "All"
        self._search_text = ""
        self._build_ui()

    def _build_ui(self):
        """Build the history panel layout."""
        # Header
        header = ctk.CTkFrame(self, fg_color="transparent")
        header.pack(fill="x", padx=20, pady=(20, 12))

        ctk.CTkLabel(
            header,
            text="CHANGE HISTORY",
            font=FONTS["heading"],
            text_color=COLORS["text_primary"],
        ).pack(side="left")

        # Filter + Search row
        controls = ctk.CTkFrame(self, fg_color="transparent")
        controls.pack(fill="x", padx=20, pady=(0, 12))

        # Filter dropdown
        filter_label = ctk.CTkLabel(
            controls,
            text="Filter:",
            font=FONTS["body"],
            text_color=COLORS["text_secondary"],
        )
        filter_label.pack(side="left", padx=(0, 8))

        self._filter_var = ctk.StringVar(value="All")
        self._filter_dropdown = ctk.CTkOptionMenu(
            controls,
            variable=self._filter_var,
            values=["All", "Added", "Modified", "Deleted", "Renamed"],
            font=FONTS["body"],
            fg_color=COLORS["bg_tertiary"],
            button_color=COLORS["accent"],
            button_hover_color=COLORS["accent_hover"],
            dropdown_fg_color=COLORS["bg_secondary"],
            dropdown_hover_color=COLORS["bg_tertiary"],
            dropdown_text_color=COLORS["text_primary"],
            text_color=COLORS["text_primary"],
            corner_radius=8,
            width=140,
            command=self._on_filter_change,
        )
        self._filter_dropdown.pack(side="left", padx=(0, 16))

        # Search
        search_label = ctk.CTkLabel(
            controls,
            text="🔎",
            font=("Segoe UI", 14),
        )
        search_label.pack(side="left", padx=(0, 4))

        self._search_entry = ctk.CTkEntry(
            controls,
            placeholder_text="Search filename...",
            font=FONTS["body"],
            fg_color=COLORS["bg_input"],
            border_color=COLORS["border"],
            text_color=COLORS["text_primary"],
            placeholder_text_color=COLORS["text_muted"],
            corner_radius=8,
            width=250,
        )
        self._search_entry.pack(side="left", padx=(0, 8))
        self._search_entry.bind("<KeyRelease>", self._on_search_change)

        # Refresh button
        refresh_btn = ctk.CTkButton(
            controls,
            text="↻  Refresh",
            font=FONTS["body"],
            fg_color=COLORS["bg_tertiary"],
            hover_color=COLORS["border_hover"],
            text_color=COLORS["text_primary"],
            corner_radius=8,
            width=100,
            command=self.refresh,
        )
        refresh_btn.pack(side="right")

        # Scrollable events list
        self._events_scroll = ctk.CTkScrollableFrame(
            self,
            fg_color=COLORS["bg_primary"],
            scrollbar_button_color=COLORS["border"],
            scrollbar_button_hover_color=COLORS["border_hover"],
        )
        self._events_scroll.pack(fill="both", expand=True, padx=20, pady=(0, 20))

        # Initial empty state
        self._empty_label = ctk.CTkLabel(
            self._events_scroll,
            text="No change history yet.\n\nChanges will appear here after scanning or monitoring.",
            font=FONTS["body"],
            text_color=COLORS["text_secondary"],
        )
        self._empty_label.pack(pady=40)

    def _on_filter_change(self, value: str):
        """Handle filter dropdown change."""
        self._current_filter = value
        self.refresh()

    def _on_search_change(self, event=None):
        """Handle search text change."""
        self._search_text = self._search_entry.get().strip()
        self.refresh()

    def refresh(self):
        """Refresh the events list from the database."""
        # Clear existing
        for widget in self._events_scroll.winfo_children():
            widget.destroy()

        # Query events
        filter_val = self._current_filter if self._current_filter != "All" else None
        search_val = self._search_text if self._search_text else None
        events = self.app.db.get_events(
            event_filter=filter_val,
            search=search_val,
            limit=500,
        )

        if not events:
            empty_msg = "No change history yet."
            if filter_val or search_val:
                empty_msg = "No events match the current filter."
            self._empty_label = ctk.CTkLabel(
                self._events_scroll,
                text=empty_msg,
                font=FONTS["body"],
                text_color=COLORS["text_secondary"],
            )
            self._empty_label.pack(pady=40)
            return

        # Date grouping
        current_date = None
        for event in events:
            # Date header
            ts = event.get("timestamp", "")
            try:
                dt = datetime.fromisoformat(ts)
                event_date = dt.strftime("%B %d, %Y")
            except (ValueError, TypeError):
                event_date = "Unknown Date"

            if event_date != current_date:
                current_date = event_date
                date_label = ctk.CTkLabel(
                    self._events_scroll,
                    text=event_date,
                    font=("Segoe UI", 11, "bold"),
                    text_color=COLORS["text_secondary"],
                    anchor="w",
                )
                date_label.pack(fill="x", pady=(12, 4))

            # Event entry
            time_str = format_time_short(ts)
            entry = ChangeEntry(
                self._events_scroll,
                event_type=event["event_type"],
                file_path=event["file_path"],
                timestamp=time_str,
                on_click=lambda e=event: self._show_detail(e),
            )
            entry.pack(fill="x", pady=2)

    def _show_detail(self, event: dict):
        """Show detailed info for a change event."""
        detail_window = ctk.CTkToplevel(self)
        detail_window.title("File Details")
        detail_window.geometry("500x400")
        detail_window.resizable(False, False)
        detail_window.configure(fg_color=COLORS["bg_primary"])
        detail_window.transient(self.winfo_toplevel())
        detail_window.grab_set()

        config = EVENT_CONFIG.get(event["event_type"], EVENT_CONFIG["MODIFIED"])

        # Header
        header = ctk.CTkLabel(
            detail_window,
            text=f"{config['icon']}  FILE DETAILS",
            font=FONTS["heading"],
            text_color=COLORS["text_primary"],
        )
        header.pack(padx=20, pady=(20, 16))

        # Details card
        card = Card(detail_window)
        card.pack(fill="both", expand=True, padx=20, pady=(0, 20))

        fields = [
            ("Filename", Path(event["file_path"]).name),
            ("Path", event["file_path"]),
            ("Event", f"{config['icon']}  {config['label']}"),
        ]

        if event.get("old_hash"):
            fields.append(("Previous SHA-256", event["old_hash"]))
        if event.get("new_hash"):
            fields.append(("Current SHA-256", event["new_hash"]))
        if event.get("file_size") is not None:
            fields.append(("File size", format_size(event["file_size"])))
        if event.get("old_path"):
            fields.append(("Previous path", event["old_path"]))
        if event.get("timestamp"):
            fields.append(("Detected", format_timestamp(event["timestamp"])))

        for label, value in fields:
            row = ctk.CTkFrame(card, fg_color="transparent")
            row.pack(fill="x", padx=16, pady=4)

            ctk.CTkLabel(
                row,
                text=label,
                font=FONTS["body_small"],
                text_color=COLORS["text_secondary"],
                width=120,
                anchor="w",
            ).pack(side="left")

            val_font = FONTS["mono_small"] if "SHA-256" in label else FONTS["body"]
            ctk.CTkLabel(
                row,
                text=str(value),
                font=val_font,
                text_color=COLORS["text_primary"],
                anchor="w",
                wraplength=300,
            ).pack(side="left", fill="x", expand=True)

        ctk.CTkButton(
            detail_window,
            text="Close",
            font=FONTS["button"],
            fg_color=COLORS["bg_tertiary"],
            hover_color=COLORS["border_hover"],
            text_color=COLORS["text_primary"],
            corner_radius=8,
            width=100,
            command=detail_window.destroy,
        ).pack(pady=(0, 16))

        detail_window.after(100, detail_window.focus_force)
