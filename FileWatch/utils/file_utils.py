"""
FileWatch — File Utility Functions

Formatting helpers for file sizes, timestamps, and path checks.
"""

from datetime import datetime
from pathlib import Path


def format_size(size_bytes: int | None) -> str:
    """
    Format a byte count into a human-readable string.

    Examples:
        format_size(0) -> "0 B"
        format_size(1024) -> "1.0 KB"
        format_size(1_500_000) -> "1.4 MB"
        format_size(2_000_000_000) -> "1.9 GB"
    """
    if size_bytes is None or size_bytes < 0:
        return "—"

    if size_bytes == 0:
        return "0 B"

    units = [
        (1_099_511_627_776, "TB"),
        (1_073_741_824, "GB"),
        (1_048_576, "MB"),
        (1_024, "KB"),
    ]

    for threshold, unit in units:
        if size_bytes >= threshold:
            return f"{size_bytes / threshold:.1f} {unit}"

    return f"{size_bytes} B"


def format_timestamp(dt: datetime | str | None) -> str:
    """
    Format a datetime into a readable string.

    Examples:
        format_timestamp(datetime(2026, 8, 11, 21, 44, 5)) -> "August 11, 2026 21:44:05"
    """
    if dt is None:
        return "—"

    if isinstance(dt, str):
        try:
            dt = datetime.fromisoformat(dt)
        except ValueError:
            return dt

    return dt.strftime("%B %d, %Y %H:%M:%S")


def format_time_short(dt: datetime | str | None) -> str:
    """
    Format a datetime into a short time string (HH:MM).

    Examples:
        format_time_short(datetime(2026, 8, 11, 21, 44, 5)) -> "21:44"
    """
    if dt is None:
        return "—"

    if isinstance(dt, str):
        try:
            dt = datetime.fromisoformat(dt)
        except ValueError:
            return dt

    return dt.strftime("%H:%M")


def is_ignored(path: Path | str, ignored_folders: list[str] | set[str]) -> bool:
    """
    Check if a path contains any ignored folder names.

    Args:
        path: The file path to check.
        ignored_folders: Collection of folder names to ignore.

    Returns:
        True if the path traverses an ignored folder.
    """
    parts = Path(path).parts
    return any(part in ignored_folders for part in parts)


def truncate_hash(hash_str: str | None, length: int = 12) -> str:
    """
    Truncate a hex hash string for display.

    Examples:
        truncate_hash("a7c3f8d1e591e2...") -> "a7c3f8d1e591..."
    """
    if not hash_str:
        return "—"
    if len(hash_str) <= length:
        return hash_str
    return hash_str[:length] + "..."


def get_filename(path: str) -> str:
    """Extract just the filename from a relative path."""
    return Path(path).name
