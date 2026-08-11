"""
FileWatch — Recursive File Scanner

Recursively walks a directory, computing SHA-256 hashes for each file.
Skips configured ignored directories and collects access errors without crashing.
"""

import os
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Callable

from core.hasher import compute_sha256

# Default directories to ignore during scanning
DEFAULT_IGNORED_FOLDERS = {".git", ".venv", "venv", "node_modules", "__pycache__", ".idea", ".vscode"}


@dataclass
class FileInfo:
    """Represents a scanned file's metadata and hash."""
    relative_path: str
    absolute_path: str
    sha256: str
    file_size: int
    modified_at: float  # Unix timestamp


@dataclass
class ScanResult:
    """The complete result of a directory scan."""
    folder_path: str
    files: list[FileInfo] = field(default_factory=list)
    skipped_files: list[tuple[str, str]] = field(default_factory=list)  # (path, error_reason)
    total_size: int = 0
    scan_time: datetime = field(default_factory=datetime.now)


def count_files(
    root: Path,
    ignored_folders: set[str] | None = None,
) -> int:
    """
    Count the total number of files in a directory tree for progress tracking.

    Args:
        root: Root directory to count files in.
        ignored_folders: Set of folder names to skip.

    Returns:
        Total number of scannable files.
    """
    if ignored_folders is None:
        ignored_folders = DEFAULT_IGNORED_FOLDERS

    count = 0
    try:
        for dirpath, dirnames, filenames in os.walk(root):
            # Filter out ignored directories in-place to prevent os.walk from descending
            dirnames[:] = [d for d in dirnames if d not in ignored_folders]
            count += len(filenames)
    except OSError:
        pass
    return count


def scan_directory(
    root: Path,
    ignored_folders: set[str] | None = None,
    progress_callback: Callable[[int, int], None] | None = None,
) -> ScanResult:
    """
    Recursively scan a directory, computing SHA-256 hashes for all files.

    Args:
        root: Root directory to scan.
        ignored_folders: Set of folder names to skip (e.g., '.git', 'node_modules').
        progress_callback: Called with (current_file_index, total_files) during scan.

    Returns:
        ScanResult containing all scanned files, skipped files, and metadata.
    """
    if ignored_folders is None:
        ignored_folders = DEFAULT_IGNORED_FOLDERS

    root = Path(root).resolve()
    result = ScanResult(folder_path=str(root))

    # First pass: count files for progress tracking
    total_files = count_files(root, ignored_folders)
    current = 0

    try:
        for dirpath, dirnames, filenames in os.walk(root):
            # Filter out ignored directories in-place
            dirnames[:] = sorted(d for d in dirnames if d not in ignored_folders)

            for filename in sorted(filenames):
                current += 1
                filepath = Path(dirpath) / filename

                # Report progress
                if progress_callback:
                    progress_callback(current, total_files)

                try:
                    relative = str(filepath.relative_to(root))
                except ValueError:
                    result.skipped_files.append((str(filepath), "Could not determine relative path"))
                    continue

                # Compute hash
                file_hash, file_size = compute_sha256(filepath)

                if file_hash is None:
                    result.skipped_files.append((relative, "Could not read file (permission denied or locked)"))
                    continue

                # Get modification time
                try:
                    mtime = filepath.stat().st_mtime
                except OSError:
                    result.skipped_files.append((relative, "Could not read file metadata"))
                    continue

                file_info = FileInfo(
                    relative_path=relative,
                    absolute_path=str(filepath),
                    sha256=file_hash,
                    file_size=file_size,
                    modified_at=mtime,
                )
                result.files.append(file_info)
                result.total_size += file_size

    except PermissionError:
        result.skipped_files.append((str(root), "Permission denied for root directory"))
    except OSError as e:
        result.skipped_files.append((str(root), f"OS error: {e}"))

    return result
