# GitHub Repo Analyzer

A simple desktop app that fetches and displays key stats for any **public** GitHub repository.

Enter a URL like `https://github.com/python/cpython`, click **ANALYZE**, and instantly see:

| Stat | Example |
|------|---------|
| Repository name | cpython |
| ⭐ Stars | 65 234 |
| 🍴 Forks | 31 012 |
| 🐛 Open issues | 8 421 |
| 💻 Main language | Python |
| 📅 Last updated | Aug 14, 2026 |

## Prerequisites

- **Python 3.10+** (Tkinter is included with standard Python installations)

## Quick Start

```bash
# 1. Install the one dependency
pip install -r requirements.txt

# 2. Run the app
python main.py
```

That's it — a window will open and you're ready to go.

## How It Works

1. You paste a public GitHub repo URL into the text field.
2. The app extracts the `owner/repo` from the URL.
3. It calls the [GitHub REST API](https://docs.github.com/en/rest/repos/repos#get-a-repository) (`GET /repos/{owner}/{repo}`) — no authentication needed for public repos.
4. The response is parsed and displayed in a clean dark-themed UI.

## Error Handling

- **Invalid URL** → friendly message asking for the correct format.
- **Repo not found (404)** → tells you to double-check the name.
- **Rate limited (403)** → suggests waiting a minute (GitHub allows 60 unauthenticated requests/hour).
- **No internet** → network error message.

## Project Structure

```
github-repo-analyzer/
├── main.py              # The entire application (< 200 lines)
├── requirements.txt     # Just "requests"
└── README.md            # You are here
```

## License

This project is released into the public domain — use it however you like.
