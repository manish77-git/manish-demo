"""
FileWatch — Configuration Manager

Loads and saves application settings to a local JSON file.
"""

import json
from pathlib import Path

# Default configuration values
DEFAULTS = {
    "last_folder": "",
    "ignored_folders": [".git", ".venv", "venv", "node_modules", "__pycache__", ".idea", ".vscode"],
    "auto_monitor": True,
    "recursive": True,
}

CONFIG_FILENAME = "filewatch_config.json"


class Config:
    """Application configuration backed by a local JSON file."""

    def __init__(self, config_dir: str | Path | None = None):
        """
        Args:
            config_dir: Directory to store the config file.
                       Defaults to the current working directory.
        """
        if config_dir:
            self._path = Path(config_dir) / CONFIG_FILENAME
        else:
            self._path = Path(CONFIG_FILENAME)

        self._data: dict = {}
        self._load()

    def _load(self):
        """Load config from disk, falling back to defaults."""
        if self._path.exists():
            try:
                with open(self._path, "r", encoding="utf-8") as f:
                    self._data = json.load(f)
            except (json.JSONDecodeError, OSError):
                self._data = {}

        # Merge with defaults for any missing keys
        for key, default in DEFAULTS.items():
            if key not in self._data:
                self._data[key] = default

    def save(self):
        """Persist config to disk."""
        try:
            self._path.parent.mkdir(parents=True, exist_ok=True)
            with open(self._path, "w", encoding="utf-8") as f:
                json.dump(self._data, f, indent=2)
        except OSError:
            pass  # Non-critical — settings won't persist but app still works

    @property
    def last_folder(self) -> str:
        return self._data.get("last_folder", "")

    @last_folder.setter
    def last_folder(self, value: str):
        self._data["last_folder"] = value
        self.save()

    @property
    def ignored_folders(self) -> list[str]:
        return self._data.get("ignored_folders", DEFAULTS["ignored_folders"])

    @ignored_folders.setter
    def ignored_folders(self, value: list[str]):
        self._data["ignored_folders"] = value
        self.save()

    @property
    def auto_monitor(self) -> bool:
        return self._data.get("auto_monitor", True)

    @auto_monitor.setter
    def auto_monitor(self, value: bool):
        self._data["auto_monitor"] = value
        self.save()

    @property
    def recursive(self) -> bool:
        return self._data.get("recursive", True)

    @recursive.setter
    def recursive(self, value: bool):
        self._data["recursive"] = value
        self.save()
