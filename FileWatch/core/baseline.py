"""
FileWatch — Baseline Manager

A baseline is a trusted snapshot of the files in a folder.
Future scans compare the current files against this snapshot to detect changes.
"""

from datetime import datetime

from core.scanner import ScanResult


def create_baseline(db, folder_path: str, scan_result: ScanResult) -> int:
    """
    Create a new baseline from scan results, replacing any existing baseline for this folder.

    Args:
        db: Database instance.
        folder_path: The monitored folder path.
        scan_result: The scan result containing file data.

    Returns:
        The new baseline ID.
    """
    return db.save_baseline(folder_path, scan_result)


def get_baseline_files(db, folder_path: str) -> dict[str, dict] | None:
    """
    Retrieve the current baseline files for a folder.

    Args:
        db: Database instance.
        folder_path: The monitored folder path.

    Returns:
        A dict mapping relative_path -> {sha256, file_size, modified_at},
        or None if no baseline exists.
    """
    return db.get_baseline_files(folder_path)


def baseline_exists(db, folder_path: str) -> bool:
    """Check whether a baseline exists for the given folder."""
    return db.baseline_exists(folder_path)


def get_baseline_info(db, folder_path: str) -> dict | None:
    """
    Get metadata about the current baseline.

    Returns:
        A dict with 'created_at', 'file_count', 'total_size', or None if no baseline.
    """
    return db.get_baseline_info(folder_path)
