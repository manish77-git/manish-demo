"""
FileWatch — Change Detector

Compares current filesystem state against a baseline to classify changes as:
  ADDED    — file exists now but not in baseline
  MODIFIED — file exists in both but SHA-256 differs
  DELETED  — file existed in baseline but not now
  RENAMED  — a deleted file's hash matches an added file's hash (same content, new name)
"""

from dataclasses import dataclass
from datetime import datetime


@dataclass
class ChangeEvent:
    """Represents a detected file change."""
    event_type: str          # "ADDED", "MODIFIED", "DELETED", "RENAMED"
    file_path: str           # Relative path (new path for renames)
    old_hash: str | None     # Previous SHA-256 (None for ADDED)
    new_hash: str | None     # Current SHA-256 (None for DELETED)
    file_size: int | None    # Current file size (None for DELETED)
    timestamp: datetime      # When the change was detected
    old_path: str | None = None  # Previous path (only for RENAMED)


def compare_with_baseline(
    baseline_files: dict[str, dict],
    current_files: dict[str, dict],
) -> list[ChangeEvent]:
    """
    Compare current filesystem state against a baseline snapshot.

    Args:
        baseline_files: Dict mapping relative_path -> {sha256, file_size, modified_at}
                       from the stored baseline.
        current_files: Dict mapping relative_path -> {sha256, file_size}
                      from the current scan.

    Returns:
        List of ChangeEvent objects describing all detected changes.
    """
    now = datetime.now()
    changes: list[ChangeEvent] = []
    added_files: list[ChangeEvent] = []
    deleted_files: list[ChangeEvent] = []

    baseline_paths = set(baseline_files.keys())
    current_paths = set(current_files.keys())

    # Deleted: in baseline but not in current
    for path in sorted(baseline_paths - current_paths):
        bl = baseline_files[path]
        deleted_files.append(ChangeEvent(
            event_type="DELETED",
            file_path=path,
            old_hash=bl["sha256"],
            new_hash=None,
            file_size=None,
            timestamp=now,
        ))

    # Added: in current but not in baseline
    for path in sorted(current_paths - baseline_paths):
        cur = current_files[path]
        added_files.append(ChangeEvent(
            event_type="ADDED",
            file_path=path,
            old_hash=None,
            new_hash=cur["sha256"],
            file_size=cur["file_size"],
            timestamp=now,
        ))

    # Modified: in both but hash differs
    for path in sorted(baseline_paths & current_paths):
        bl = baseline_files[path]
        cur = current_files[path]
        if bl["sha256"] != cur["sha256"]:
            changes.append(ChangeEvent(
                event_type="MODIFIED",
                file_path=path,
                old_hash=bl["sha256"],
                new_hash=cur["sha256"],
                file_size=cur["file_size"],
                timestamp=now,
            ))

    # Rename detection: match deleted+added files with identical hashes
    renamed = _detect_renames(deleted_files, added_files)
    for rename_event in renamed:
        changes.append(rename_event)

    # Add remaining (non-renamed) deleted and added events
    # _detect_renames returns the rename events and modifies deleted/added lists
    changes.extend(deleted_files)
    changes.extend(added_files)

    # Sort by timestamp, then by path
    changes.sort(key=lambda c: (c.timestamp, c.file_path))

    return changes


def _detect_renames(
    deleted_files: list[ChangeEvent],
    added_files: list[ChangeEvent],
) -> list[ChangeEvent]:
    """
    Detect renames by matching deleted files with added files that have the same hash.
    Modifies deleted_files and added_files in-place by removing matched pairs.

    Returns:
        List of RENAMED ChangeEvent objects.
    """
    renames: list[ChangeEvent] = []

    # Build a hash -> list of added events lookup
    added_by_hash: dict[str, list[ChangeEvent]] = {}
    for event in added_files:
        if event.new_hash:
            added_by_hash.setdefault(event.new_hash, []).append(event)

    matched_deleted = []
    matched_added = set()

    for del_event in deleted_files:
        if not del_event.old_hash:
            continue

        candidates = added_by_hash.get(del_event.old_hash, [])
        for add_event in candidates:
            if id(add_event) in matched_added:
                continue

            # Match found: same hash means same content, different path means rename
            renames.append(ChangeEvent(
                event_type="RENAMED",
                file_path=add_event.file_path,
                old_hash=del_event.old_hash,
                new_hash=add_event.new_hash,
                file_size=add_event.file_size,
                timestamp=del_event.timestamp,
                old_path=del_event.file_path,
            ))
            matched_deleted.append(del_event)
            matched_added.add(id(add_event))
            break  # One rename per deleted file

    # Remove matched events from the original lists
    for event in matched_deleted:
        deleted_files.remove(event)
    added_files[:] = [e for e in added_files if id(e) not in matched_added]

    return renames
