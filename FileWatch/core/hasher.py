"""
FileWatch — SHA-256 File Hasher

Computes SHA-256 cryptographic hashes for files using chunked/streaming reads.
SHA-256 is a cryptographic hash function used here as a file fingerprint.
If file contents change, the resulting hash will normally change.
"""

import hashlib
from pathlib import Path

# 1 MB chunk size for streaming reads — avoids loading large files into memory
CHUNK_SIZE = 1_048_576  # 1 MB


def compute_sha256(filepath: Path, chunk_size: int = CHUNK_SIZE) -> tuple[str | None, int | None]:
    """
    Compute the SHA-256 hash of a file using chunked streaming reads.

    Args:
        filepath: Path to the file to hash.
        chunk_size: Number of bytes to read per chunk (default 1 MB).

    Returns:
        A tuple of (hex_digest, file_size) on success.
        Returns (None, None) if the file cannot be read.
    """
    sha256 = hashlib.sha256()
    file_size = 0

    try:
        with open(filepath, "rb") as f:
            while True:
                chunk = f.read(chunk_size)
                if not chunk:
                    break
                sha256.update(chunk)
                file_size += len(chunk)
        return sha256.hexdigest(), file_size
    except FileNotFoundError:
        return None, None
    except PermissionError:
        return None, None
    except OSError:
        # Covers: file locked, invalid path, I/O errors, file disappearing mid-read
        return None, None
