"""
GitHub Repository Analyzer
A simple Tkinter app that fetches and displays public GitHub repository stats.
"""

import re
import tkinter as tk
from tkinter import font as tkfont
from datetime import datetime

import requests


# ───────────────────────── GitHub API Helper ─────────────────────────

def parse_repo_url(url: str) -> tuple[str, str] | None:
    """
    Extract (owner, repo) from a GitHub URL.
    Accepts formats like:
        https://github.com/owner/repo
        https://github.com/owner/repo/
        github.com/owner/repo
    Returns None if the URL doesn't match.
    """
    pattern = r"(?:https?://)?github\.com/([A-Za-z0-9_.\-]+)/([A-Za-z0-9_.\-]+)/?$"
    match = re.match(pattern, url.strip())
    if match:
        return match.group(1), match.group(2)
    return None


def fetch_repo_info(owner: str, repo: str) -> dict:
    """
    Call the GitHub REST API and return a simplified dict of repo info.
    Raises ValueError with a user-friendly message on failure.
    """
    api_url = f"https://api.github.com/repos/{owner}/{repo}"
    response = requests.get(api_url, timeout=10)

    if response.status_code == 404:
        raise ValueError("Repository not found.\nDouble-check the owner and repo name.")
    if response.status_code == 403:
        raise ValueError("API rate limit exceeded.\nPlease wait a minute and try again.")
    if response.status_code != 200:
        raise ValueError(f"GitHub API error (HTTP {response.status_code}).")

    data = response.json()

    # Format the date nicely  →  "Aug 14, 2026"
    updated_raw = data.get("updated_at", "")
    try:
        updated_dt = datetime.strptime(updated_raw, "%Y-%m-%dT%H:%M:%SZ")
        updated_str = updated_dt.strftime("%b %d, %Y")
    except ValueError:
        updated_str = updated_raw

    return {
        "name": data.get("name", "N/A"),
        "stars": data.get("stargazers_count", 0),
        "forks": data.get("forks_count", 0),
        "open_issues": data.get("open_issues_count", 0),
        "language": data.get("language") or "N/A",
        "updated": updated_str,
    }


# ───────────────────────── Colour Palette ────────────────────────────

BG          = "#0d1117"   # GitHub-dark background
SURFACE     = "#161b22"   # Card / input background
BORDER      = "#30363d"   # Subtle borders
TEXT        = "#e6edf3"   # Primary text
TEXT_DIM    = "#8b949e"   # Secondary / muted text
ACCENT      = "#58a6ff"   # Links & highlights
ACCENT_HOVER = "#79c0ff"
GREEN       = "#3fb950"   # Success colour
RED         = "#f85149"   # Error colour
BUTTON_BG   = "#238636"   # Green button
BUTTON_HOVER = "#2ea043"


# ───────────────────────── Application ───────────────────────────────

class RepoAnalyzerApp:
    """Single-screen Tkinter GUI for the GitHub Repo Analyzer."""

    def __init__(self, root: tk.Tk) -> None:
        self.root = root
        self.root.title("GitHub Repo Analyzer")
        self.root.configure(bg=BG)
        self.root.resizable(False, False)

        # Centre the window on screen
        win_w, win_h = 520, 560
        screen_w = self.root.winfo_screenwidth()
        screen_h = self.root.winfo_screenheight()
        x = (screen_w - win_w) // 2
        y = (screen_h - win_h) // 2
        self.root.geometry(f"{win_w}x{win_h}+{x}+{y}")

        # ── Fonts ──
        self.font_title = tkfont.Font(family="Segoe UI", size=18, weight="bold")
        self.font_sub   = tkfont.Font(family="Segoe UI", size=10)
        self.font_entry = tkfont.Font(family="Consolas", size=11)
        self.font_btn   = tkfont.Font(family="Segoe UI", size=11, weight="bold")
        self.font_label = tkfont.Font(family="Segoe UI", size=12)
        self.font_value = tkfont.Font(family="Segoe UI", size=12, weight="bold")
        self.font_msg   = tkfont.Font(family="Segoe UI", size=10)

        self._build_ui()

    # ────────────── UI Construction ──────────────

    def _build_ui(self) -> None:
        pad_x = 36

        # Title
        tk.Label(
            self.root, text="GitHub Repo Analyzer", font=self.font_title,
            bg=BG, fg=TEXT,
        ).pack(pady=(28, 2))

        tk.Label(
            self.root, text="Enter a public repository URL to get started",
            font=self.font_sub, bg=BG, fg=TEXT_DIM,
        ).pack(pady=(0, 18))

        # URL entry
        entry_frame = tk.Frame(self.root, bg=BORDER, bd=0, highlightthickness=0)
        entry_frame.pack(padx=pad_x, fill="x")

        inner = tk.Frame(entry_frame, bg=SURFACE, bd=0)
        inner.pack(padx=1, pady=1, fill="x")

        self.url_var = tk.StringVar()
        self.entry = tk.Entry(
            inner, textvariable=self.url_var, font=self.font_entry,
            bg=SURFACE, fg=TEXT, insertbackground=TEXT,
            relief="flat", bd=8,
        )
        self.entry.pack(fill="x")
        self.entry.bind("<Return>", lambda _e: self._on_analyze())

        # Analyze button
        self.btn = tk.Label(
            self.root, text="ANALYZE", font=self.font_btn,
            bg=BUTTON_BG, fg="#ffffff", cursor="hand2",
            padx=28, pady=8,
        )
        self.btn.pack(pady=(16, 0))
        self.btn.bind("<Button-1>", lambda _e: self._on_analyze())
        self.btn.bind("<Enter>", lambda _e: self.btn.configure(bg=BUTTON_HOVER))
        self.btn.bind("<Leave>", lambda _e: self.btn.configure(bg=BUTTON_BG))

        # Status message (errors / "loading…")
        self.status_var = tk.StringVar()
        self.status_label = tk.Label(
            self.root, textvariable=self.status_var, font=self.font_msg,
            bg=BG, fg=RED, wraplength=440,
        )
        self.status_label.pack(pady=(8, 0))

        # ── Results card ──
        self.card = tk.Frame(self.root, bg=SURFACE, highlightbackground=BORDER,
                             highlightthickness=1, bd=0)
        # (not packed yet — shown after a successful fetch)

        # Separator inside the card
        self.separator = tk.Frame(self.card, bg=BORDER, height=1)
        self.separator.pack(fill="x", padx=16, pady=(12, 8))

        # Six stat rows
        self._stat_labels: dict[str, tk.Label] = {}
        stats = [
            ("name",        "Repository"),
            ("stars",       "⭐  Stars"),
            ("forks",       "🍴  Forks"),
            ("open_issues", "🐛  Issues"),
            ("language",    "💻  Language"),
            ("updated",     "📅  Updated"),
        ]
        for key, label_text in stats:
            row = tk.Frame(self.card, bg=SURFACE)
            row.pack(fill="x", padx=20, pady=4)

            tk.Label(
                row, text=label_text, font=self.font_label,
                bg=SURFACE, fg=TEXT_DIM, anchor="w", width=14,
            ).pack(side="left")

            val = tk.Label(
                row, text="—", font=self.font_value,
                bg=SURFACE, fg=TEXT, anchor="w",
            )
            val.pack(side="left", fill="x", expand=True)
            self._stat_labels[key] = val

    # ────────────── Event Handler ──────────────

    def _on_analyze(self) -> None:
        url = self.url_var.get().strip()
        if not url:
            self._show_error("Please enter a GitHub repository URL.")
            return

        parsed = parse_repo_url(url)
        if parsed is None:
            self._show_error("Invalid URL format.\nExpected: https://github.com/owner/repo")
            return

        owner, repo = parsed

        # Show loading state
        self.status_label.configure(fg=TEXT_DIM)
        self.status_var.set("Fetching repository info…")
        self.card.pack_forget()
        self.root.update_idletasks()

        try:
            info = fetch_repo_info(owner, repo)
        except ValueError as exc:
            self._show_error(str(exc))
            return
        except requests.ConnectionError:
            self._show_error("Network error. Check your internet connection.")
            return
        except requests.Timeout:
            self._show_error("Request timed out. Try again later.")
            return
        except Exception as exc:
            self._show_error(f"Unexpected error: {exc}")
            return

        # Populate the card
        self._stat_labels["name"].configure(text=info["name"], fg=ACCENT)
        self._stat_labels["stars"].configure(text=str(info["stars"]))
        self._stat_labels["forks"].configure(text=str(info["forks"]))
        self._stat_labels["open_issues"].configure(text=str(info["open_issues"]))
        self._stat_labels["language"].configure(text=info["language"])
        self._stat_labels["updated"].configure(text=info["updated"])

        # Show the card
        self.status_var.set("")
        self.card.pack(padx=36, pady=(14, 20), fill="x")

    def _show_error(self, message: str) -> None:
        self.card.pack_forget()
        self.status_label.configure(fg=RED)
        self.status_var.set(message)


# ───────────────────────── Entry Point ───────────────────────────────

if __name__ == "__main__":
    root = tk.Tk()
    RepoAnalyzerApp(root)
    root.mainloop()
