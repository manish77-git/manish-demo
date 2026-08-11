"""
FileWatch — SQLite Database

Stores baselines, file snapshots, and change event history.
All queries use parameterized SQL (? placeholders) — no string concatenation.
Thread-safe via per-method connections or a shared lock.
"""

import csv
import sqlite3
import threading
from datetime import datetime
from pathlib import Path

from core.scanner import ScanResult


class Database:
    """SQLite database for FileWatch baseline and event storage."""

    def __init__(self, db_path: str | Path = "filewatch.db"):
        self.db_path = str(db_path)
        self._lock = threading.Lock()
        self._init_db()

    def _get_connection(self) -> sqlite3.Connection:
        """Create a new connection for the current thread."""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA journal_mode=WAL")
        conn.execute("PRAGMA foreign_keys=ON")
        return conn

    def _init_db(self):
        """Create tables if they don't exist."""
        with self._lock:
            conn = self._get_connection()
            try:
                conn.executescript("""
                    CREATE TABLE IF NOT EXISTS baselines (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        folder_path TEXT NOT NULL,
                        created_at TEXT NOT NULL
                    );

                    CREATE TABLE IF NOT EXISTS files (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        baseline_id INTEGER NOT NULL,
                        relative_path TEXT NOT NULL,
                        file_size INTEGER NOT NULL,
                        sha256 TEXT NOT NULL,
                        modified_at REAL NOT NULL,
                        FOREIGN KEY (baseline_id) REFERENCES baselines(id) ON DELETE CASCADE
                    );

                    CREATE INDEX IF NOT EXISTS idx_files_baseline_id
                        ON files(baseline_id);

                    CREATE TABLE IF NOT EXISTS events (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        timestamp TEXT NOT NULL,
                        event_type TEXT NOT NULL,
                        file_path TEXT NOT NULL,
                        old_hash TEXT,
                        new_hash TEXT,
                        file_size INTEGER,
                        old_path TEXT
                    );

                    CREATE INDEX IF NOT EXISTS idx_events_timestamp
                        ON events(timestamp);
                    CREATE INDEX IF NOT EXISTS idx_events_event_type
                        ON events(event_type);
                """)
                conn.commit()
            finally:
                conn.close()

    def save_baseline(self, folder_path: str, scan_result: ScanResult) -> int:
        """
        Save a new baseline, replacing any existing baseline for this folder.

        Returns:
            The new baseline ID.
        """
        with self._lock:
            conn = self._get_connection()
            try:
                # Delete old baselines and their files for this folder
                cursor = conn.execute(
                    "SELECT id FROM baselines WHERE folder_path = ?",
                    (folder_path,)
                )
                for row in cursor.fetchall():
                    conn.execute("DELETE FROM files WHERE baseline_id = ?", (row["id"],))
                conn.execute("DELETE FROM baselines WHERE folder_path = ?", (folder_path,))

                # Insert new baseline
                now = datetime.now().isoformat()
                cursor = conn.execute(
                    "INSERT INTO baselines (folder_path, created_at) VALUES (?, ?)",
                    (folder_path, now)
                )
                baseline_id = cursor.lastrowid

                # Insert files
                file_rows = [
                    (baseline_id, f.relative_path, f.file_size, f.sha256, f.modified_at)
                    for f in scan_result.files
                ]
                conn.executemany(
                    "INSERT INTO files (baseline_id, relative_path, file_size, sha256, modified_at) "
                    "VALUES (?, ?, ?, ?, ?)",
                    file_rows
                )

                conn.commit()
                return baseline_id
            finally:
                conn.close()

    def baseline_exists(self, folder_path: str) -> bool:
        """Check if a baseline exists for the given folder."""
        with self._lock:
            conn = self._get_connection()
            try:
                cursor = conn.execute(
                    "SELECT COUNT(*) as cnt FROM baselines WHERE folder_path = ?",
                    (folder_path,)
                )
                return cursor.fetchone()["cnt"] > 0
            finally:
                conn.close()

    def get_baseline_files(self, folder_path: str) -> dict[str, dict] | None:
        """
        Get all files from the current baseline for a folder.

        Returns:
            Dict mapping relative_path -> {sha256, file_size, modified_at},
            or None if no baseline exists.
        """
        with self._lock:
            conn = self._get_connection()
            try:
                cursor = conn.execute(
                    "SELECT id FROM baselines WHERE folder_path = ? ORDER BY id DESC LIMIT 1",
                    (folder_path,)
                )
                row = cursor.fetchone()
                if not row:
                    return None

                baseline_id = row["id"]
                cursor = conn.execute(
                    "SELECT relative_path, sha256, file_size, modified_at "
                    "FROM files WHERE baseline_id = ?",
                    (baseline_id,)
                )

                files = {}
                for row in cursor.fetchall():
                    files[row["relative_path"]] = {
                        "sha256": row["sha256"],
                        "file_size": row["file_size"],
                        "modified_at": row["modified_at"],
                    }
                return files
            finally:
                conn.close()

    def get_baseline_info(self, folder_path: str) -> dict | None:
        """
        Get metadata about the current baseline.

        Returns:
            Dict with 'created_at', 'file_count', 'total_size', or None.
        """
        with self._lock:
            conn = self._get_connection()
            try:
                cursor = conn.execute(
                    "SELECT id, created_at FROM baselines WHERE folder_path = ? ORDER BY id DESC LIMIT 1",
                    (folder_path,)
                )
                row = cursor.fetchone()
                if not row:
                    return None

                baseline_id = row["id"]
                created_at = row["created_at"]

                cursor = conn.execute(
                    "SELECT COUNT(*) as cnt, COALESCE(SUM(file_size), 0) as total "
                    "FROM files WHERE baseline_id = ?",
                    (baseline_id,)
                )
                stats = cursor.fetchone()

                return {
                    "created_at": created_at,
                    "file_count": stats["cnt"],
                    "total_size": stats["total"],
                }
            finally:
                conn.close()

    def save_event(self, event_type: str, file_path: str,
                   old_hash: str | None = None, new_hash: str | None = None,
                   file_size: int | None = None, old_path: str | None = None,
                   timestamp: datetime | None = None):
        """Save a change event to the history."""
        with self._lock:
            conn = self._get_connection()
            try:
                ts = (timestamp or datetime.now()).isoformat()
                conn.execute(
                    "INSERT INTO events (timestamp, event_type, file_path, old_hash, new_hash, file_size, old_path) "
                    "VALUES (?, ?, ?, ?, ?, ?, ?)",
                    (ts, event_type, file_path, old_hash, new_hash, file_size, old_path)
                )
                conn.commit()
            finally:
                conn.close()

    def get_events(self, event_filter: str | None = None,
                   search: str | None = None,
                   limit: int = 500) -> list[dict]:
        """
        Retrieve change events from history.

        Args:
            event_filter: Filter by event type (e.g., "ADDED", "MODIFIED").
            search: Search substring in file_path.
            limit: Maximum number of events to return.

        Returns:
            List of event dicts, most recent first.
        """
        with self._lock:
            conn = self._get_connection()
            try:
                query = "SELECT * FROM events WHERE 1=1"
                params: list = []

                if event_filter and event_filter != "All":
                    query += " AND event_type = ?"
                    params.append(event_filter.upper())

                if search:
                    query += " AND file_path LIKE ?"
                    params.append(f"%{search}%")

                query += " ORDER BY timestamp DESC LIMIT ?"
                params.append(limit)

                cursor = conn.execute(query, params)
                return [dict(row) for row in cursor.fetchall()]
            finally:
                conn.close()

    def get_event_count_today(self) -> int:
        """Get the number of change events recorded today."""
        with self._lock:
            conn = self._get_connection()
            try:
                today = datetime.now().strftime("%Y-%m-%d")
                cursor = conn.execute(
                    "SELECT COUNT(*) as cnt FROM events WHERE timestamp >= ?",
                    (today,)
                )
                return cursor.fetchone()["cnt"]
            finally:
                conn.close()

    def get_recent_events(self, limit: int = 50) -> list[dict]:
        """Get the most recent events for the dashboard."""
        return self.get_events(limit=limit)

    def clear_history(self):
        """Delete all events from the history table."""
        with self._lock:
            conn = self._get_connection()
            try:
                conn.execute("DELETE FROM events")
                conn.commit()
            finally:
                conn.close()

    def export_to_csv(self, filepath: str):
        """
        Export all events to a CSV file.

        Args:
            filepath: Path to the CSV file to create.
        """
        events = self.get_events(limit=100_000)

        with open(filepath, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(["timestamp", "event_type", "file_path", "old_hash", "new_hash", "file_size", "old_path"])
            for event in events:
                writer.writerow([
                    event["timestamp"],
                    event["event_type"],
                    event["file_path"],
                    event.get("old_hash", ""),
                    event.get("new_hash", ""),
                    event.get("file_size", ""),
                    event.get("old_path", ""),
                ])

    def close(self):
        """No persistent connection to close — connections are per-method."""
        pass
