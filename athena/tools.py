"""Backup/undo system and CLI tool functions (tree, grep, replace, etc.)."""
import re
from pathlib import Path
from datetime import datetime
from rich.panel import Panel
from athena.config import console, C
from athena.files import TEXT_EXTENSIONS


_file_backups = {}  # {filepath_str: [(timestamp, bytes_content), ...]}

def backup_file(filepath: str) -> bool:
    """Backup a file's content before modification."""
    p = Path(filepath).resolve()
    if p.exists() and p.is_file():
        try:
            content = p.read_bytes()
            key = str(p)
            if key not in _file_backups:
                _file_backups[key] = []
            _file_backups[key].append((datetime.now().isoformat(), content))
            _file_backups[key] = _file_backups[key][-10:]
            return True
        except Exception:
            return False
    return False

def undo_last(filepath: str = None) -> tuple[bool, str]:
    """Restore the last backup. If filepath given, restore that; else most recent."""
    if filepath:
        key = str(Path(filepath).resolve())
        if key in _file_backups and _file_backups[key]:
            ts, content = _file_backups[key].pop()
            Path(key).write_bytes(content)
            return True, f"Restored {Path(key).name} from backup ({ts})"
        return False, f"No backup found for {filepath}"
    latest_key, latest_ts = None, ""
    for k, backups in _file_backups.items():
        if backups and backups[-1][0] > latest_ts:
            latest_ts = backups[-1][0]
            latest_key = k
    if latest_key:
        ts, content = _file_backups[latest_key].pop()
        Path(latest_key).write_bytes(content)
        return True, f"Restored {Path(latest_key).name} from backup ({ts})"
    return False, "No backups available."

# ──────────────────────────────────────────────────────────────────────────
#  CLI TOOL FUNCTIONS
# ──────────────────────────────────────────────────────────────────────────
def build_tree(root: str = ".", max_depth: int = 3) -> str:
    """Generate a directory tree string."""
    p = Path(root).resolve()
    if not p.exists():
        return f"[Error: {root} not found]"
    lines = [f"{p.name}/"]
    def _walk(directory, depth, prefix):
        if depth > max_depth:
            return
        try:
            entries = sorted(directory.iterdir(), key=lambda e: (not e.is_dir(), e.name.lower()))
        except PermissionError:
            return
        visible = [e for e in entries if not e.name.startswith('.')]
        for i, entry in enumerate(visible):
            is_last = (i == len(visible) - 1)
            connector = "└── " if is_last else "├── "
            extension = "    " if is_last else "│   "
            if entry.is_dir():
                lines.append(f"{prefix}{connector}{entry.name}/")
                _walk(entry, depth + 1, prefix + extension)
            else:
                sz = entry.stat().st_size
                sz_s = f"{sz}B" if sz < 1024 else f"{sz/1024:.1f}KB" if sz < 1048576 else f"{sz/1048576:.1f}MB"
                lines.append(f"{prefix}{connector}{entry.name} ({sz_s})")
    _walk(p, 1, "")
    return "\n".join(lines)

def grep_in_files(pattern: str, root: str = ".", max_results: int = 80) -> list[tuple[str, int, str]]:
    """Grep for pattern across text files. Returns [(rel_path, line_no, line_text)]."""
    p = Path(root).resolve()
    results = []
    try:
        regex = re.compile(pattern, re.IGNORECASE)
    except re.error:
        regex = re.compile(re.escape(pattern), re.IGNORECASE)
    skip_dirs = {'node_modules', '__pycache__', '.git', 'venv', '.venv', 'dist', 'build', '.next', 'env'}
    def _search(directory):
        if len(results) >= max_results:
            return
        try:
            for entry in sorted(directory.iterdir()):
                if len(results) >= max_results:
                    return
                if entry.is_dir() and not entry.name.startswith('.') and entry.name not in skip_dirs:
                    _search(entry)
                elif entry.is_file() and entry.suffix.lower() in TEXT_EXTENSIONS:
                    try:
                        text = entry.read_text(encoding='utf-8', errors='replace')
                        for li, line in enumerate(text.splitlines(), 1):
                            if regex.search(line):
                                results.append((str(entry.relative_to(p)), li, line.strip()[:120]))
                                if len(results) >= max_results:
                                    return
                    except Exception:
                        pass
        except PermissionError:
            pass
    _search(p)
    return results

def confirm_action(desc: str, dangerous: bool = False) -> bool:
    """Universal permission prompt for any CLI action."""
    style = C["red"] if dangerous else C["yellow"]
    icon = "🔴 DANGER" if dangerous else "🔐 Permission"
    console.print()
    console.print(Panel(
        f"[bold {style}]{icon}[/]\n\n"
        f"[{C['white']}]{desc}[/]\n\n"
        f"[{C['dim']}][bold green]y[/bold green] = yes  |  [bold red]n[/bold red] = no[/]",
        border_style=style, padding=(0, 2),
    ))
    try:
        ans = input("  › ").strip().lower()
    except (KeyboardInterrupt, EOFError):
        ans = "n"
    return ans in ("y", "yes")

def read_file_lines(filepath: str, start: int = None, end: int = None) -> str:
    """Read specific lines from a file with line numbers."""
    p = Path(filepath).expanduser()
    if not p.exists():
        p = Path.cwd() / filepath
    if not p.exists():
        return f"[Error: file not found: {filepath}]"
    try:
        all_lines = p.read_text(encoding='utf-8', errors='replace').splitlines()
        total = len(all_lines)
        s = max(0, (start or 1) - 1)
        e = min(total, end or total)
        selected = all_lines[s:e]
        header = f"=== {p.name} (lines {s+1}-{e} of {total}) ==="
        numbered = "\n".join(f"{s+1+i:4d} │ {l}" for i, l in enumerate(selected))
        return header + "\n" + numbered
    except Exception as ex:
        return f"[Error reading {filepath}: {ex}]"

def search_replace_in_file(filepath: str, old: str, new: str, all_occurrences: bool = False) -> tuple[bool, str]:
    """Search and replace text in a file. Returns (success, message)."""
    p = Path(filepath).resolve()
    if not p.exists():
        return False, f"File not found: {filepath}"
    try:
        content = p.read_text(encoding='utf-8', errors='replace')
        count = content.count(old)
        if count == 0:
            return False, f"Pattern not found in {p.name}"
        backup_file(str(p))
        if all_occurrences:
            new_content = content.replace(old, new)
            msg = f"Replaced {count} occurrence(s) in {p.name}"
        else:
            new_content = content.replace(old, new, 1)
            msg = f"Replaced 1 occurrence in {p.name} ({count} total found)"
        p.write_text(new_content, encoding='utf-8')
        return True, msg
    except Exception as ex:
        return False, f"Error: {ex}"


