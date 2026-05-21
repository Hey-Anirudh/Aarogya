"""File handling — reading, extension detection, auto-inject."""
import re
from pathlib import Path
from athena.config import CFG, console, C


TEXT_EXTENSIONS = {
    ".py", ".js", ".ts", ".jsx", ".tsx", ".html", ".css", ".json",
    ".yaml", ".yml", ".toml", ".ini", ".cfg", ".env", ".md", ".txt",
    ".csv", ".xml", ".sh", ".bat", ".ps1", ".c", ".cpp", ".h", ".java",
    ".rs", ".go", ".rb", ".php", ".sql", ".dockerfile", ".gitignore",
    ".htaccess", ".log", ".conf", ".tf", ".kt", ".swift", ".r", ".lua",
    ".vim", ".zsh", ".fish", ".el", ".clj", ".ex", ".exs",
}

def read_file(path: str, max_chars: int = 16000) -> str:
    p = Path(path).expanduser()
    if not p.exists():
        p = Path.cwd() / path
    if not p.exists():
        return f"[Error: file not found: {path}]"
    try:
        suffix = p.suffix.lower()
        if suffix not in TEXT_EXTENSIONS:
            # Binary file
            size = p.stat().st_size
            return f"[Binary file: {p.name}, {size/1024:.1f}KB — cannot display]"
        content = p.read_text(encoding="utf-8", errors="replace")
        size_kb = p.stat().st_size / 1024
        truncated = ""
        if len(content) > max_chars:
            truncated = f"\n\n[… truncated: showing {max_chars} of {len(content)} chars ({size_kb:.1f}KB total)]"
            content = content[:max_chars]
        lang = p.suffix.lstrip(".") or "text"
        return (
            f"=== FILE: {p.resolve()} ({size_kb:.1f}KB) ===\n"
            f"```{lang}\n{content}\n```{truncated}"
        )
    except Exception as e:
        return f"[Error reading {path}: {e}]"

def read_multiple_files(paths: list[str]) -> str:
    return "\n\n".join(read_file(p) for p in paths)

FILE_REF_RE = re.compile(
    r'\b([\w\-\.]+\.(?:' +
    "|".join(ext.lstrip(".") for ext in TEXT_EXTENSIONS) +
    r'))\b',
    re.IGNORECASE,
)

FILE_ACTION_WORDS = {
    "analyse", "analyze", "read", "check", "look", "review", "explain",
    "show", "open", "inspect", "debug", "fix", "improve", "refactor",
    "understand", "summarize", "what", "how", "find", "search", "count",
    "modify", "edit", "update", "change", "rewrite", "convert", "parse",
    "run", "execute", "test",
}

def auto_inject_files(user_message: str) -> tuple[str, list[str]]:
    if not CFG.get("auto_file_detect", True):
        return user_message, []

    msg_lower = user_message.lower()
    has_action = any(w in msg_lower for w in FILE_ACTION_WORDS)
    refs_found = FILE_REF_RE.findall(user_message)

    # Smart Extensionless File Matcher:
    # If no references found with extensions, scan the words in the user message
    # and check if they match any file basenames in the workspace.
    if not refs_found and has_action:
        cwd = Path.cwd()
        local_files = []
        try:
            local_files = [f for f in cwd.iterdir() if f.is_file()]
        except Exception:
            pass
        msg_words = set(re.findall(r'\b[a-zA-Z0-9_]+\b', user_message))
        for f in local_files:
            if f.stem.lower() in [w.lower() for w in msg_words]:
                if len(f.stem) > 2 and f.suffix in TEXT_EXTENSIONS:
                    refs_found.append(f.name)

    if not refs_found:
        return user_message, []

    cwd = Path.cwd()
    found_paths = []
    seen = set()
    for fname in refs_found:
        if fname in seen:
            continue
        seen.add(fname)
        for candidate in [cwd / fname, Path(fname).expanduser()]:
            if candidate.exists() and candidate.is_file():
                found_paths.append(str(candidate))
                break

    if not found_paths:
        return user_message, []

    injected = []
    extra = []
    for fpath in found_paths[:4]:
        content = read_file(fpath)
        if not content.startswith("[Error"):
            extra.append(content)
            injected.append(Path(fpath).name)

    if not extra:
        return user_message, []

    augmented = (
        user_message
        + "\n\n[Athena auto-read these files from disk:]\n"
        + "\n\n".join(extra)
    )
    return augmented, injected

