"""
FileWatch — Real-Time Filesystem Monitor

Uses watchdog to detect filesystem events (created, modified, deleted, moved).
Includes debouncing to prevent duplicate events from the OS from spamming history.
"""

import threading
import time
from pathlib import Path
from typing import Callable

from watchdog.observers import Observer
from watchdog.events import (
    FileSystemEventHandler,
    FileCreatedEvent,
    FileModifiedEvent,
    FileDeletedEvent,
    FileMovedEvent,
)

from core.hasher import compute_sha256


# Debounce interval in seconds — events within this window are consolidated
DEBOUNCE_SECONDS = 0.5


class _DebouncedHandler(FileSystemEventHandler):
    """
    Filesystem event handler with debouncing.

    Consolidates rapid duplicate events (common on Windows/macOS) into a single
    processed event per file path.
    """

    def __init__(
        self,
        root_path: Path,
        ignored_folders: set[str],
        baseline_files: dict[str, dict],
        on_change: Callable,
        debounce_seconds: float = DEBOUNCE_SECONDS,
    ):
        super().__init__()
        self.root_path = root_path
        self.ignored_folders = ignored_folders
        self.baseline_files = baseline_files
        self.on_change = on_change
        self.debounce_seconds = debounce_seconds

        # Debounce state: {path_str: threading.Timer}
        self._timers: dict[str, threading.Timer] = {}
        self._lock = threading.Lock()

    def _is_ignored(self, path: str) -> bool:
        """Check if a path falls under an ignored directory."""
        try:
            rel = Path(path).relative_to(self.root_path)
            parts = rel.parts
            return any(part in self.ignored_folders for part in parts)
        except (ValueError, TypeError):
            return False

    def _get_relative(self, path: str) -> str | None:
        """Get relative path from absolute, or None if outside root."""
        try:
            return str(Path(path).relative_to(self.root_path))
        except ValueError:
            return None

    def _debounce(self, key: str, event_type: str, path: str,
                  old_path: str | None = None):
        """Schedule a debounced event processing."""
        with self._lock:
            # Cancel any existing timer for this key
            if key in self._timers:
                self._timers[key].cancel()

            timer = threading.Timer(
                self.debounce_seconds,
                self._process_event,
                args=(event_type, path, old_path),
            )
            timer.daemon = True
            self._timers[key] = timer
            timer.start()

    def _process_event(self, event_type: str, path: str,
                       old_path: str | None = None):
        """Process a filesystem event after debouncing."""
        abs_path = Path(path)
        rel_path = self._get_relative(path)
        if rel_path is None:
            return

        # Clean up timer reference
        with self._lock:
            self._timers.pop(path, None)

        if event_type == "MOVED":
            old_rel = self._get_relative(old_path) if old_path else None
            # Compute hash of the new file
            new_hash, file_size = compute_sha256(abs_path)
            old_hash = None
            if old_rel and old_rel in self.baseline_files:
                old_hash = self.baseline_files[old_rel]["sha256"]

            if old_rel and new_hash and old_hash == new_hash:
                # Same content, different name = RENAMED
                self.on_change("RENAMED", rel_path, old_hash, new_hash, file_size, old_rel)
                # Update baseline in memory
                if old_rel in self.baseline_files:
                    self.baseline_files[rel_path] = self.baseline_files.pop(old_rel)
            else:
                # Content differs or can't determine — report as DELETE + ADD
                if old_rel:
                    old_data = self.baseline_files.get(old_rel, {})
                    self.on_change("DELETED", old_rel, old_data.get("sha256"), None, None, None)
                    self.baseline_files.pop(old_rel, None)
                if new_hash:
                    self.on_change("ADDED", rel_path, None, new_hash, file_size, None)
                    self.baseline_files[rel_path] = {"sha256": new_hash, "file_size": file_size}

        elif event_type == "CREATED":
            new_hash, file_size = compute_sha256(abs_path)
            if new_hash is None:
                return  # File might have been temporary

            if rel_path in self.baseline_files:
                # File was in baseline — check if it's actually modified
                old_hash = self.baseline_files[rel_path]["sha256"]
                if old_hash != new_hash:
                    self.on_change("MODIFIED", rel_path, old_hash, new_hash, file_size, None)
                    self.baseline_files[rel_path] = {"sha256": new_hash, "file_size": file_size}
            else:
                self.on_change("ADDED", rel_path, None, new_hash, file_size, None)
                self.baseline_files[rel_path] = {"sha256": new_hash, "file_size": file_size}

        elif event_type == "MODIFIED":
            new_hash, file_size = compute_sha256(abs_path)
            if new_hash is None:
                return

            old_hash = None
            if rel_path in self.baseline_files:
                old_hash = self.baseline_files[rel_path]["sha256"]
                if old_hash == new_hash:
                    return  # No actual content change — OS false alarm
                self.on_change("MODIFIED", rel_path, old_hash, new_hash, file_size, None)
                self.baseline_files[rel_path] = {"sha256": new_hash, "file_size": file_size}
            else:
                # Not in baseline — treat as added
                self.on_change("ADDED", rel_path, None, new_hash, file_size, None)
                self.baseline_files[rel_path] = {"sha256": new_hash, "file_size": file_size}

        elif event_type == "DELETED":
            if rel_path in self.baseline_files:
                old_hash = self.baseline_files[rel_path]["sha256"]
                self.on_change("DELETED", rel_path, old_hash, None, None, None)
                del self.baseline_files[rel_path]

    def on_created(self, event):
        if event.is_directory or self._is_ignored(event.src_path):
            return
        self._debounce(event.src_path, "CREATED", event.src_path)

    def on_modified(self, event):
        if event.is_directory or self._is_ignored(event.src_path):
            return
        self._debounce(event.src_path, "MODIFIED", event.src_path)

    def on_deleted(self, event):
        if event.is_directory or self._is_ignored(event.src_path):
            return
        self._debounce(event.src_path, "DELETED", event.src_path)

    def on_moved(self, event):
        if event.is_directory:
            return
        if self._is_ignored(event.src_path) and self._is_ignored(event.dest_path):
            return
        # Use dest_path as the debounce key for moves
        self._debounce(event.dest_path, "MOVED", event.dest_path, event.src_path)

    def cancel_all_timers(self):
        """Cancel all pending debounce timers."""
        with self._lock:
            for timer in self._timers.values():
                timer.cancel()
            self._timers.clear()


class FileWatchMonitor:
    """
    Real-time filesystem monitor using watchdog.

    Usage:
        monitor = FileWatchMonitor(folder_path, ignored, baseline, callback)
        monitor.start()
        ...
        monitor.stop()
    """

    def __init__(
        self,
        folder_path: str | Path,
        ignored_folders: set[str],
        baseline_files: dict[str, dict],
        on_change: Callable,
    ):
        """
        Args:
            folder_path: Root folder to monitor.
            ignored_folders: Set of directory names to ignore.
            baseline_files: Current baseline for comparison (will be mutated).
            on_change: Callback(event_type, file_path, old_hash, new_hash, file_size, old_path).
        """
        self.folder_path = Path(folder_path).resolve()
        self._observer = Observer()
        self._handler = _DebouncedHandler(
            root_path=self.folder_path,
            ignored_folders=ignored_folders,
            baseline_files=baseline_files,
            on_change=on_change,
        )
        self._is_running = False

    @property
    def is_running(self) -> bool:
        return self._is_running

    def start(self):
        """Start watching the folder for changes."""
        if self._is_running:
            return
        self._observer = Observer()  # Fresh observer in case of restart
        self._observer.schedule(self._handler, str(self.folder_path), recursive=True)
        self._observer.daemon = True
        self._observer.start()
        self._is_running = True

    def stop(self):
        """Stop watching the folder."""
        if not self._is_running:
            return
        self._handler.cancel_all_timers()
        self._observer.stop()
        self._observer.join(timeout=2)
        self._is_running = False

    def update_baseline(self, baseline_files: dict[str, dict]):
        """Update the in-memory baseline reference."""
        self._handler.baseline_files = baseline_files
