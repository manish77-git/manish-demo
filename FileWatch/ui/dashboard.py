"""
FileWatch — Dashboard Panel

Main dashboard showing folder selection, baseline status, monitoring controls,
recent changes, and stats. All scan/hash operations run in background threads.
"""

import threading
from datetime import datetime
from pathlib import Path
from tkinter import filedialog

import customtkinter as ctk

from ui.components import (
    COLORS, FONTS, EVENT_CONFIG,
    Card, SectionLabel, StatCard, StatusBadge, ChangeEntry, ToastNotification, ConfirmDialog,
)
from utils.file_utils import format_size, format_timestamp, format_time_short


class DashboardPanel(ctk.CTkFrame):
    """Main dashboard panel for FileWatch."""

    def __init__(self, master, app_controller):
        """
        Args:
            master: Parent widget.
            app_controller: The main AppController with access to db, config, scanner, etc.
        """
        super().__init__(master, fg_color=COLORS["bg_primary"])
        self.app = app_controller
        self._scanning = False
        self._build_ui()
        self._refresh_state()

    def _build_ui(self):
        """Construct the dashboard layout."""
        # Scrollable container
        self._scroll = ctk.CTkScrollableFrame(
            self,
            fg_color=COLORS["bg_primary"],
            scrollbar_button_color=COLORS["border"],
            scrollbar_button_hover_color=COLORS["border_hover"],
        )
        self._scroll.pack(fill="both", expand=True, padx=0, pady=0)

        container = self._scroll

        # ── MONITORED FOLDER SECTION ──
        SectionLabel(container, text="Monitored Folder").pack(
            anchor="w", padx=20, pady=(20, 8)
        )

        folder_card = Card(container)
        folder_card.pack(fill="x", padx=20, pady=(0, 12))

        self._folder_label = ctk.CTkLabel(
            folder_card,
            text="📁  No folder selected",
            font=FONTS["body"],
            text_color=COLORS["text_secondary"],
            anchor="w",
        )
        self._folder_label.pack(fill="x", padx=16, pady=(16, 12))

        btn_frame = ctk.CTkFrame(folder_card, fg_color="transparent")
        btn_frame.pack(fill="x", padx=16, pady=(0, 16))

        self._select_btn = ctk.CTkButton(
            btn_frame,
            text="Select Folder",
            font=FONTS["button"],
            fg_color=COLORS["accent"],
            hover_color=COLORS["accent_hover"],
            corner_radius=8,
            width=140,
            command=self._on_select_folder,
        )
        self._select_btn.pack(side="left", padx=(0, 8))

        self._baseline_btn = ctk.CTkButton(
            btn_frame,
            text="Create Baseline",
            font=FONTS["button"],
            fg_color=COLORS["bg_tertiary"],
            hover_color=COLORS["border_hover"],
            text_color=COLORS["text_primary"],
            corner_radius=8,
            width=150,
            command=self._on_create_baseline,
            state="disabled",
        )
        self._baseline_btn.pack(side="left", padx=(0, 8))

        self._scan_btn = ctk.CTkButton(
            btn_frame,
            text="Scan Now",
            font=FONTS["button"],
            fg_color=COLORS["bg_tertiary"],
            hover_color=COLORS["border_hover"],
            text_color=COLORS["text_primary"],
            corner_radius=8,
            width=110,
            command=self._on_scan_now,
            state="disabled",
        )
        self._scan_btn.pack(side="left")

        # ── BASELINE INFO ──
        self._baseline_card = Card(container)
        self._baseline_card.pack(fill="x", padx=20, pady=(0, 12))

        SectionLabel(self._baseline_card, text="Baseline").pack(
            anchor="w", padx=16, pady=(12, 4)
        )

        self._baseline_info_label = ctk.CTkLabel(
            self._baseline_card,
            text="No baseline created yet.\n\nA baseline is a trusted snapshot of the files in this folder.\nFuture scans compare the current files against this snapshot.",
            font=FONTS["body_small"],
            text_color=COLORS["text_secondary"],
            anchor="w",
            justify="left",
        )
        self._baseline_info_label.pack(fill="x", padx=16, pady=(0, 12))

        # ── PROGRESS BAR (hidden by default) ──
        self._progress_frame = Card(container)
        # Don't pack initially — shown during scans

        self._progress_label = ctk.CTkLabel(
            self._progress_frame,
            text="Scanning...",
            font=FONTS["body"],
            text_color=COLORS["text_primary"],
            anchor="w",
        )
        self._progress_label.pack(fill="x", padx=16, pady=(12, 4))

        self._progress_bar = ctk.CTkProgressBar(
            self._progress_frame,
            fg_color=COLORS["bg_tertiary"],
            progress_color=COLORS["accent"],
            corner_radius=6,
            height=8,
        )
        self._progress_bar.pack(fill="x", padx=16, pady=(0, 4))
        self._progress_bar.set(0)

        self._progress_detail = ctk.CTkLabel(
            self._progress_frame,
            text="0 / 0 files",
            font=FONTS["body_small"],
            text_color=COLORS["text_secondary"],
            anchor="w",
        )
        self._progress_detail.pack(fill="x", padx=16, pady=(0, 12))

        # ── STATUS & STATS ──
        SectionLabel(container, text="System Status").pack(
            anchor="w", padx=20, pady=(8, 8)
        )

        status_card = Card(container)
        status_card.pack(fill="x", padx=20, pady=(0, 12))

        status_top = ctk.CTkFrame(status_card, fg_color="transparent")
        status_top.pack(fill="x", padx=16, pady=(12, 8))

        self._status_badge = StatusBadge(status_top, text="Inactive", status="inactive")
        self._status_badge.pack(side="left")

        self._monitor_btn = ctk.CTkButton(
            status_top,
            text="Start Monitoring",
            font=FONTS["button"],
            fg_color=COLORS["green"],
            hover_color="#4cc95f",
            corner_radius=8,
            width=160,
            command=self._on_toggle_monitoring,
            state="disabled",
        )
        self._monitor_btn.pack(side="right")

        # Stats row
        stats_frame = ctk.CTkFrame(status_card, fg_color="transparent")
        stats_frame.pack(fill="x", padx=8, pady=(0, 12))
        stats_frame.columnconfigure((0, 1, 2, 3), weight=1)

        self._stat_files = StatCard(stats_frame, label="Files Tracked", value="—")
        self._stat_files.grid(row=0, column=0, padx=4, pady=4, sticky="nsew")

        self._stat_changes = StatCard(stats_frame, label="Changes Today", value="0")
        self._stat_changes.grid(row=0, column=1, padx=4, pady=4, sticky="nsew")

        self._stat_scan = StatCard(stats_frame, label="Last Scan", value="—")
        self._stat_scan.grid(row=0, column=2, padx=4, pady=4, sticky="nsew")

        self._stat_size = StatCard(stats_frame, label="Total Size", value="—")
        self._stat_size.grid(row=0, column=3, padx=4, pady=4, sticky="nsew")

        # ── RECENT CHANGES ──
        SectionLabel(container, text="Recent Changes").pack(
            anchor="w", padx=20, pady=(8, 8)
        )

        self._changes_frame = ctk.CTkFrame(container, fg_color="transparent")
        self._changes_frame.pack(fill="x", padx=20, pady=(0, 20))

        self._no_changes_label = ctk.CTkLabel(
            self._changes_frame,
            text="✅  No changes detected",
            font=FONTS["body"],
            text_color=COLORS["text_secondary"],
        )
        self._no_changes_label.pack(pady=20)

    # ──────────────────────────────────────────────────────────────────
    # ACTIONS
    # ──────────────────────────────────────────────────────────────────

    def _on_select_folder(self):
        """Open native folder picker."""
        initial = self.app.config.last_folder or None
        folder = filedialog.askdirectory(
            title="Select Folder to Monitor",
            initialdir=initial,
        )
        if not folder:
            return

        folder_path = Path(folder).resolve()
        if not folder_path.is_dir():
            self._show_toast("⚠️ Unable to access folder. Check permissions and try again.", "error")
            return

        self.app.set_folder(str(folder_path))
        self._folder_label.configure(
            text=f"📁  {folder_path}",
            text_color=COLORS["text_primary"],
        )
        self._baseline_btn.configure(state="normal")
        self._refresh_state()

    def _on_create_baseline(self):
        """Create or replace baseline for the selected folder."""
        if not self.app.current_folder:
            return

        # Check if baseline already exists
        if self.app.baseline_exists():
            ConfirmDialog(
                self,
                title="Replace Baseline?",
                message="This will make the current state the new trusted baseline.\n\nPrevious baseline data will be replaced.",
                confirm_text="Replace",
                cancel_text="Cancel",
                on_confirm=self._run_baseline_scan,
            )
        else:
            self._run_baseline_scan()

    def _run_baseline_scan(self):
        """Run baseline scan in background thread."""
        if self._scanning:
            return
        self._scanning = True

        # Show progress
        self._progress_frame.pack(fill="x", padx=20, pady=(0, 12),
                                  before=self._changes_frame.master if hasattr(self._changes_frame, 'master') else None)
        # Repack after status card
        self._progress_frame.pack_forget()
        # Find the right position — after baseline card
        self._progress_frame.pack(fill="x", padx=20, pady=(0, 12), after=self._baseline_card)

        self._progress_label.configure(text="Creating baseline...")
        self._progress_bar.set(0)
        self._progress_detail.configure(text="Counting files...")
        self._baseline_btn.configure(state="disabled")
        self._scan_btn.configure(state="disabled")

        def progress_callback(current, total):
            self.after(0, lambda c=current, t=total: self._update_progress(c, t, "Creating baseline..."))

        def scan_thread():
            try:
                result = self.app.create_baseline(progress_callback=progress_callback)
                self.after(0, lambda: self._on_baseline_complete(result))
            except Exception as e:
                self.after(0, lambda: self._on_scan_error(str(e)))

        thread = threading.Thread(target=scan_thread, daemon=True)
        thread.start()

    def _on_scan_now(self):
        """Run a comparison scan in background thread."""
        if self._scanning or not self.app.current_folder or not self.app.baseline_exists():
            return
        self._scanning = True

        self._progress_frame.pack_forget()
        self._progress_frame.pack(fill="x", padx=20, pady=(0, 12), after=self._baseline_card)
        self._progress_label.configure(text="Scanning...")
        self._progress_bar.set(0)
        self._progress_detail.configure(text="Counting files...")
        self._scan_btn.configure(state="disabled")

        def progress_callback(current, total):
            self.after(0, lambda c=current, t=total: self._update_progress(c, t, "Scanning..."))

        def scan_thread():
            try:
                changes, skipped = self.app.scan_now(progress_callback=progress_callback)
                self.after(0, lambda: self._on_scan_complete(changes, skipped))
            except Exception as e:
                self.after(0, lambda: self._on_scan_error(str(e)))

        thread = threading.Thread(target=scan_thread, daemon=True)
        thread.start()

    def _on_toggle_monitoring(self):
        """Start or stop real-time monitoring."""
        if self.app.is_monitoring:
            self.app.stop_monitoring()
            self._monitor_btn.configure(
                text="Start Monitoring",
                fg_color=COLORS["green"],
                hover_color="#4cc95f",
            )
            self._status_badge.set_status("Monitoring Stopped", "stopped")
            self._show_toast("🔴 Monitoring stopped", "warning")
        else:
            success = self.app.start_monitoring()
            if success:
                self._monitor_btn.configure(
                    text="Stop Monitoring",
                    fg_color=COLORS["red"],
                    hover_color="#d43d36",
                )
                self._status_badge.set_status("Monitoring Active", "active")
                self._show_toast("🟢 Monitoring started", "success")
            else:
                self._show_toast("⚠️ Cannot start monitoring. Create a baseline first.", "error")

    # ──────────────────────────────────────────────────────────────────
    # UI UPDATES (called from main thread via self.after)
    # ──────────────────────────────────────────────────────────────────

    def _update_progress(self, current: int, total: int, label: str):
        """Update progress bar from main thread."""
        if total > 0:
            progress = current / total
            self._progress_bar.set(progress)
            self._progress_detail.configure(text=f"{current} / {total} files")
            self._progress_label.configure(text=label)

    def _on_baseline_complete(self, result):
        """Handle baseline creation completion."""
        self._scanning = False
        self._progress_frame.pack_forget()
        self._baseline_btn.configure(state="normal")
        self._scan_btn.configure(state="normal")
        self._monitor_btn.configure(state="normal")

        if result:
            total_files = len(result.files)
            skipped = len(result.skipped_files)
            msg = f"✅ Baseline created — {total_files} files tracked"
            if skipped > 0:
                msg += f" ({skipped} skipped)"
            self._show_toast(msg, "success")

            # Auto-start monitoring if configured
            if self.app.config.auto_monitor:
                self.after(500, self._on_toggle_monitoring)

        self._refresh_state()

    def _on_scan_complete(self, changes, skipped):
        """Handle scan completion."""
        self._scanning = False
        self._progress_frame.pack_forget()
        self._scan_btn.configure(state="normal")

        added = sum(1 for c in changes if c.event_type == "ADDED")
        modified = sum(1 for c in changes if c.event_type == "MODIFIED")
        deleted = sum(1 for c in changes if c.event_type == "DELETED")
        renamed = sum(1 for c in changes if c.event_type == "RENAMED")
        total = len(changes)

        if total == 0:
            baseline_info = self.app.get_baseline_info()
            file_count = baseline_info["file_count"] if baseline_info else 0
            msg = f"✅ No changes detected. {file_count} files match the baseline."
            if skipped:
                msg += f" ({len(skipped)} files skipped due to access errors)"
            self._show_toast(msg, "success")
        else:
            parts = []
            if modified: parts.append(f"{modified} modified")
            if added: parts.append(f"{added} added")
            if deleted: parts.append(f"{deleted} deleted")
            if renamed: parts.append(f"{renamed} renamed")
            msg = f"⚠️ {total} changes detected: {', '.join(parts)}"
            if skipped:
                msg += f" ({len(skipped)} files skipped)"
            self._show_toast(msg, "warning")

        self._refresh_state()
        self._refresh_changes()

    def _on_scan_error(self, error_msg: str):
        """Handle scan error."""
        self._scanning = False
        self._progress_frame.pack_forget()
        self._baseline_btn.configure(state="normal")
        self._scan_btn.configure(state="normal")
        self._show_toast(f"⚠️ Scan error: {error_msg}", "error")

    def _refresh_state(self):
        """Refresh all dashboard state from the app controller."""
        # Folder display
        if self.app.current_folder:
            self._folder_label.configure(
                text=f"📁  {self.app.current_folder}",
                text_color=COLORS["text_primary"],
            )
            self._baseline_btn.configure(state="normal" if not self._scanning else "disabled")
        else:
            self._folder_label.configure(
                text="📁  No folder selected",
                text_color=COLORS["text_secondary"],
            )

        # Baseline info
        info = self.app.get_baseline_info()
        if info:
            created = format_timestamp(info["created_at"])
            self._baseline_info_label.configure(
                text=f"Created: {created}\n"
                     f"Files: {info['file_count']}\n"
                     f"Total size: {format_size(info['total_size'])}\n"
                     f"Status: 🟢 Baseline Active",
            )
            self._scan_btn.configure(state="normal" if not self._scanning else "disabled")
            self._monitor_btn.configure(state="normal")

            # Stats
            self._stat_files.set_value(str(info["file_count"]))
            self._stat_size.set_value(format_size(info["total_size"]))
        else:
            self._baseline_info_label.configure(
                text="No baseline created yet.\n\n"
                     "A baseline is a trusted snapshot of the files in this folder.\n"
                     "Future scans compare the current files against this snapshot.",
            )
            self._scan_btn.configure(state="disabled")
            self._monitor_btn.configure(state="disabled")

        # Changes today
        changes_today = self.app.db.get_event_count_today()
        self._stat_changes.set_value(str(changes_today))

        # Last scan time
        last_scan = self.app.last_scan_time
        if last_scan:
            self._stat_scan.set_value(last_scan.strftime("%H:%M:%S"))
        else:
            self._stat_scan.set_value("—")

        # Monitoring status
        if self.app.is_monitoring:
            self._status_badge.set_status("Monitoring Active", "active")
            self._monitor_btn.configure(
                text="Stop Monitoring",
                fg_color=COLORS["red"],
                hover_color="#d43d36",
            )
        else:
            if info:
                self._status_badge.set_status("Monitoring Stopped", "stopped")
            else:
                self._status_badge.set_status("Inactive", "inactive")

        self._refresh_changes()

    def _refresh_changes(self):
        """Refresh the recent changes list."""
        # Clear existing
        for widget in self._changes_frame.winfo_children():
            widget.destroy()

        events = self.app.db.get_recent_events(limit=30)

        if not events:
            self._no_changes_label = ctk.CTkLabel(
                self._changes_frame,
                text="✅  No changes detected",
                font=FONTS["body"],
                text_color=COLORS["text_secondary"],
            )
            self._no_changes_label.pack(pady=20)
            return

        for event in events:
            ts = ""
            if event.get("timestamp"):
                ts = format_time_short(event["timestamp"])

            entry = ChangeEntry(
                self._changes_frame,
                event_type=event["event_type"],
                file_path=event["file_path"],
                timestamp=ts,
                on_click=lambda e=event: self._show_event_detail(e),
            )
            entry.pack(fill="x", pady=2)

    def _show_event_detail(self, event: dict):
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

        # Close button
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

    def _show_toast(self, message: str, toast_type: str = "info"):
        """Show a toast notification."""
        toast = ToastNotification(self, message=message, toast_type=toast_type)
        toast.place(relx=0.5, rely=0.95, anchor="s")

    def on_realtime_change(self, event_type, file_path, old_hash, new_hash, file_size, old_path):
        """Called from monitor when a real-time change is detected (via self.after)."""
        self._refresh_state()

        config = EVENT_CONFIG.get(event_type, EVENT_CONFIG["MODIFIED"])
        filename = Path(file_path).name
        self._show_toast(f"{config['icon']}  {config['label']}: {filename}", "warning")
