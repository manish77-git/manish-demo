"""
FileWatch — File Integrity Monitoring System
=============================================

A local file integrity monitoring application that uses SHA-256 hashing
and real-time filesystem monitoring to detect file changes.

Entry point: python app.py
"""

import sys
import os
import threading
from datetime import datetime
from pathlib import Path

# Ensure the project root is on sys.path so imports work
PROJECT_ROOT = Path(__file__).parent.resolve()
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

import customtkinter as ctk

from database.db import Database
from utils.config import Config
from core.scanner import scan_directory, ScanResult
from core.baseline import create_baseline, get_baseline_files, baseline_exists, get_baseline_info
from core.detector import compare_with_baseline, ChangeEvent
from core.monitor import FileWatchMonitor
from ui.dashboard import DashboardPanel
from ui.history import HistoryPanel
from ui.settings import SettingsPanel
from ui.components import COLORS, FONTS


class AppController:
    """
    Central controller connecting the UI, database, scanner, and monitor.

    The UI panels access this controller for all operations.
    """

    def __init__(self):
        self.db = Database(db_path=PROJECT_ROOT / "filewatch.db")
        self.config = Config(config_dir=PROJECT_ROOT)
        self.current_folder: str | None = None
        self.last_scan_time: datetime | None = None
        self._monitor: FileWatchMonitor | None = None
        self._baseline_files_cache: dict[str, dict] | None = None

        # Restore last folder from config
        if self.config.last_folder and Path(self.config.last_folder).is_dir():
            self.current_folder = self.config.last_folder

        # UI callback — set by the main window
        self._on_realtime_change_callback = None

    def set_folder(self, folder_path: str):
        """Set the currently monitored folder."""
        self.current_folder = folder_path
        self.config.last_folder = folder_path
        self._baseline_files_cache = None

    def baseline_exists(self) -> bool:
        """Check if a baseline exists for the current folder."""
        if not self.current_folder:
            return False
        return baseline_exists(self.db, self.current_folder)

    def get_baseline_info(self) -> dict | None:
        """Get baseline metadata."""
        if not self.current_folder:
            return None
        return get_baseline_info(self.db, self.current_folder)

    def create_baseline(self, progress_callback=None) -> ScanResult | None:
        """Create a baseline for the current folder."""
        if not self.current_folder:
            return None

        # Stop monitoring if running
        self.stop_monitoring()

        ignored = set(self.config.ignored_folders)
        result = scan_directory(
            root=Path(self.current_folder),
            ignored_folders=ignored,
            progress_callback=progress_callback,
        )

        create_baseline(self.db, self.current_folder, result)
        self._baseline_files_cache = None
        self.last_scan_time = datetime.now()

        return result

    def scan_now(self, progress_callback=None) -> tuple[list[ChangeEvent], list]:
        """
        Perform a full comparison scan against the baseline.

        Returns:
            Tuple of (changes, skipped_files).
        """
        if not self.current_folder:
            return [], []

        # Get baseline
        baseline_files = get_baseline_files(self.db, self.current_folder)
        if baseline_files is None:
            return [], []

        # Scan current state
        ignored = set(self.config.ignored_folders)
        result = scan_directory(
            root=Path(self.current_folder),
            ignored_folders=ignored,
            progress_callback=progress_callback,
        )

        # Build current files dict
        current_files = {}
        for f in result.files:
            current_files[f.relative_path] = {
                "sha256": f.sha256,
                "file_size": f.file_size,
            }

        # Compare
        changes = compare_with_baseline(baseline_files, current_files)

        # Save events to database
        for change in changes:
            self.db.save_event(
                event_type=change.event_type,
                file_path=change.file_path,
                old_hash=change.old_hash,
                new_hash=change.new_hash,
                file_size=change.file_size,
                old_path=change.old_path,
                timestamp=change.timestamp,
            )

        self.last_scan_time = datetime.now()
        return changes, result.skipped_files

    @property
    def is_monitoring(self) -> bool:
        return self._monitor is not None and self._monitor.is_running

    def start_monitoring(self) -> bool:
        """Start real-time monitoring. Returns True on success."""
        if not self.current_folder:
            return False

        # Get baseline
        baseline_files = get_baseline_files(self.db, self.current_folder)
        if baseline_files is None:
            return False

        # Cache a mutable copy for the monitor
        self._baseline_files_cache = dict(baseline_files)

        ignored = set(self.config.ignored_folders)

        def on_change(event_type, file_path, old_hash, new_hash, file_size, old_path):
            """Called from watchdog thread — save to DB and notify UI."""
            self.db.save_event(
                event_type=event_type,
                file_path=file_path,
                old_hash=old_hash,
                new_hash=new_hash,
                file_size=file_size,
                old_path=old_path,
            )
            self.last_scan_time = datetime.now()

            # Notify UI on main thread
            if self._on_realtime_change_callback:
                self._on_realtime_change_callback(
                    event_type, file_path, old_hash, new_hash, file_size, old_path
                )

        self._monitor = FileWatchMonitor(
            folder_path=self.current_folder,
            ignored_folders=ignored,
            baseline_files=self._baseline_files_cache,
            on_change=on_change,
        )
        self._monitor.start()
        return True

    def stop_monitoring(self):
        """Stop real-time monitoring."""
        if self._monitor:
            self._monitor.stop()
            self._monitor = None

    def shutdown(self):
        """Clean shutdown."""
        self.stop_monitoring()
        self.db.close()


class FileWatchApp(ctk.CTk):
    """Main FileWatch application window."""

    def __init__(self):
        super().__init__()

        # Window configuration
        self.title("FileWatch — File Integrity Monitoring")
        self.geometry("900x720")
        self.minsize(760, 560)
        self.configure(fg_color=COLORS["bg_primary"])

        # Set appearance
        ctk.set_appearance_mode("dark")
        ctk.set_default_color_theme("blue")

        # Controller
        self.controller = AppController()

        # Wire up real-time change callback to marshal to main thread
        self.controller._on_realtime_change_callback = self._on_realtime_change_from_monitor

        # Build UI
        self._build_ui()

        # Clean shutdown handler
        self.protocol("WM_DELETE_WINDOW", self._on_close)

    def _build_ui(self):
        """Build the main window layout."""
        # ── TOP HEADER ──
        header = ctk.CTkFrame(self, fg_color=COLORS["bg_secondary"], height=64, corner_radius=0)
        header.pack(fill="x")
        header.pack_propagate(False)

        # App title
        title_frame = ctk.CTkFrame(header, fg_color="transparent")
        title_frame.pack(side="left", padx=20)

        ctk.CTkLabel(
            title_frame,
            text="🔐  FileWatch",
            font=FONTS["title"],
            text_color=COLORS["text_primary"],
        ).pack(side="left")

        ctk.CTkLabel(
            title_frame,
            text="   Local File Integrity Monitoring",
            font=FONTS["subtitle"],
            text_color=COLORS["text_secondary"],
        ).pack(side="left", pady=(4, 0))

        # ── NAVIGATION TABS ──
        nav = ctk.CTkFrame(self, fg_color=COLORS["bg_secondary"], height=40, corner_radius=0)
        nav.pack(fill="x")
        nav.pack_propagate(False)

        self._tab_buttons: dict[str, ctk.CTkButton] = {}
        tabs = [
            ("Dashboard", "📊"),
            ("History", "📜"),
            ("Settings", "⚙️"),
        ]

        for name, icon in tabs:
            btn = ctk.CTkButton(
                nav,
                text=f"{icon}  {name}",
                font=FONTS["body"],
                fg_color="transparent",
                hover_color=COLORS["bg_tertiary"],
                text_color=COLORS["text_secondary"],
                corner_radius=0,
                width=120,
                height=36,
                command=lambda n=name: self._switch_tab(n),
            )
            btn.pack(side="left", padx=2)
            self._tab_buttons[name] = btn

        # Divider
        divider = ctk.CTkFrame(self, fg_color=COLORS["border"], height=1, corner_radius=0)
        divider.pack(fill="x")

        # ── CONTENT AREA ──
        self._content = ctk.CTkFrame(self, fg_color=COLORS["bg_primary"], corner_radius=0)
        self._content.pack(fill="both", expand=True)

        # Create panels
        self._dashboard = DashboardPanel(self._content, self.controller)
        self._history = HistoryPanel(self._content, self.controller)
        self._settings = SettingsPanel(self._content, self.controller)

        self._panels = {
            "Dashboard": self._dashboard,
            "History": self._history,
            "Settings": self._settings,
        }

        # Show dashboard by default
        self._current_tab = None
        self._switch_tab("Dashboard")

    def _switch_tab(self, tab_name: str):
        """Switch between panels."""
        if self._current_tab == tab_name:
            return

        # Hide current
        for panel in self._panels.values():
            panel.pack_forget()

        # Update tab button styles
        for name, btn in self._tab_buttons.items():
            if name == tab_name:
                btn.configure(
                    fg_color=COLORS["accent_dim"],
                    text_color=COLORS["accent"],
                )
            else:
                btn.configure(
                    fg_color="transparent",
                    text_color=COLORS["text_secondary"],
                )

        # Show target panel
        self._panels[tab_name].pack(fill="both", expand=True)
        self._current_tab = tab_name

        # Refresh data when switching
        if tab_name == "History":
            self._history.refresh()
        elif tab_name == "Dashboard":
            self._dashboard._refresh_state()

    def _on_realtime_change_from_monitor(self, event_type, file_path, old_hash, new_hash, file_size, old_path):
        """Marshal real-time change notification to the main thread."""
        self.after(0, lambda: self._dashboard.on_realtime_change(
            event_type, file_path, old_hash, new_hash, file_size, old_path
        ))

    def _on_close(self):
        """Handle window close — clean shutdown."""
        self.controller.shutdown()
        self.destroy()


def main():
    app = FileWatchApp()
    app.mainloop()


if __name__ == "__main__":
    main()
