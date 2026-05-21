"""Code detection, language guessing, and dangerous-command patterns."""
import re
from typing import Optional
from pygments.lexers import guess_lexer
from pygments.util import ClassNotFound
from athena.config import IS_WINDOWS


CODE_BLOCK_RE = re.compile(r"```(\w+)?\n(.*?)```", re.DOTALL)

def extract_code_blocks(text: str) -> list[tuple[str, str]]:
    return CODE_BLOCK_RE.findall(text)

def extract_commands_from_text(text: str) -> list[tuple[str, str]]:
    """If no code blocks, try to infer shell commands from natural language."""
    verbs = ["remove", "delete", "del", "rm", "copy", "cp", "move", "mv", "mkdir", "md", "echo", "write", "edit"]
    lines = text.splitlines()
    commands = []
    for line in lines:
        line = line.strip()
        if any(line.lower().startswith(v + " ") for v in verbs):
            if IS_WINDOWS:
                if "remove" in line.lower() or "delete" in line.lower():
                    line = line.replace("remove", "Remove-Item").replace("delete", "Remove-Item")
                commands.append(("powershell", line))
            else:
                commands.append(("bash", line))
    return commands

def detect_language(code: str, hint: str = "") -> str:
    if hint:
        return hint.lower()
    try:
        return guess_lexer(code).name.lower().split()[0]
    except ClassNotFound:
        return "text"

def clean_shell_code(code: str) -> str:
    """
    Cleans prompt prefixes from shell code blocks, e.g.:
      'C:\\Users\\Anirudh\\Desktop\\Aarogya>python athena.py' -> 'python athena.py'
      '$ ls -la' -> 'ls -la'
      'PS C:\\> Get-Process' -> 'Get-Process'
    """
    cleaned_lines = []
    for line in code.splitlines():
        line_stripped = line.strip()
        # Regex to strip common shell prompt prefixes
        m = re.match(r'^(?:PS\s+)?(?:[A-Za-z]:\\[^>]*>|>[ \t]*|[$%#][ \t]*)(.*)$', line_stripped)
        if m:
            cleaned = m.group(1).strip()
            if cleaned:
                cleaned_lines.append(cleaned)
        else:
            cleaned_lines.append(line)
    return "\n".join(cleaned_lines).strip()


DANGEROUS_PATTERNS = [
    r'\brm\s+-rf\b', r'\bdrop\s+table\b', r'\bformat\s+[a-z]:\b',
    r'\bdel\s+/[sqf]\b', r'\btruncate\b', r'\bshred\b',
    r'\b>\s*/dev/', r'\bmkfs\b', r'\bfdisk\b',
    r'\bkill\s+-9\b', r'\bpkill\b', r'\bchmod\s+777\b',
]
DANGEROUS_RE = re.compile("|".join(DANGEROUS_PATTERNS), re.IGNORECASE)

def is_dangerous(code: str) -> tuple[bool, str]:
    m = DANGEROUS_RE.search(code)
    if m:
        return True, m.group(0)
    return False, ""

def parse_plan_from_response(text: str) -> Optional[str]:
    """Extract a PLAN block from AI response if present."""
    plan_re = re.compile(r"PLAN:\n(.*?)(?:Execute\?|```|\Z)", re.DOTALL | re.IGNORECASE)
    m = plan_re.search(text)
    return m.group(1).strip() if m else None


SUPPORTED_LANGS = {
    "python", "py", "python3",
    "bash", "sh", "shell", "zsh",
    "powershell", "ps1", "ps",
    "javascript", "js", "node", "nodejs",
    "typescript", "ts",
    "batch", "bat", "cmd",
    "ruby", "rb",
    "perl", "pl",
}

NON_EXECUTABLE_LANGS = {
    "text", "txt", "markdown", "md", "json", "yaml", "yml",
    "xml", "html", "css", "diff", "csv", "sql", "none", "plain"
}

