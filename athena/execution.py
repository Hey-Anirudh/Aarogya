"""Code execution engine — runners, safety checks, AI fallback."""
import re
import subprocess
from pathlib import Path
from typing import Optional
import ollama
from rich.panel import Panel
from rich.syntax import Syntax
from athena.config import console, C, CFG, IS_WINDOWS
from athena.detection import (
    extract_code_blocks, detect_language, clean_shell_code,
    is_dangerous, SUPPORTED_LANGS, NON_EXECUTABLE_LANGS,
)
from athena.runtime import python_executable


def confirm(prompt_text: str, dangerous: bool = False) -> bool:
    if not CFG.get("confirm_all", True):
        return True  # Auto‑confirm when confirm_all is False
    style = C["red"] if dangerous else C["yellow"]
    icon  = "🔴 DANGER" if dangerous else "⚠  Confirm"
    console.print()
    console.print(Panel(
        f"[bold {style}]{icon}[/]\n\n"
        f"[{C['white']}]{prompt_text}[/]\n\n"
        f"[{C['dim']}][bold green]y[/bold green] = yes  |  [bold red]n[/bold red] = no  |  [bold {C['teal']}]e[/bold {C['teal']}] = edit first[/]",
        border_style=style,
        padding=(0, 2),
    ))
    try:
        ans = input("  › ").strip().lower()
    except (KeyboardInterrupt, EOFError):
        ans = "n"
    return ans in ("y", "yes")


def _try_run(cmd_list=None, shell_str=None, timeout=30) -> tuple[bool, str, str]:
    try:
        if shell_str is not None:
            r = subprocess.run(shell_str, shell=True, capture_output=True,
                               text=True, timeout=timeout)
        else:
            r = subprocess.run(cmd_list, capture_output=True, text=True, timeout=timeout)
        return (r.returncode == 0), r.stdout.strip(), r.stderr.strip()
    except subprocess.TimeoutExpired:
        return False, "", f"Timed out after {timeout}s"
    except FileNotFoundError as e:
        return False, "", f"Runtime not found: {e}"
    except Exception as e:
        return False, "", str(e)

NON_EXECUTABLE_LANGS = {
    "text", "txt", "markdown", "md", "json", "yaml", "yml",
    "xml", "html", "css", "diff", "csv", "sql", "none", "plain"
}

def _build_runners(lang: str, code: str) -> list[tuple[str, list, str]]:
    lang = lang.lower().strip() if lang else ""
    
    if lang in NON_EXECUTABLE_LANGS:
        return []

    if lang not in SUPPORTED_LANGS:
        if lang in NON_EXECUTABLE_LANGS:
            return []
        detected = detect_language(code)
        if detected in SUPPORTED_LANGS:
            lang = detected
        else:
            code_stripped = code.strip()
            if not code_stripped:
                return []
            shell_keywords = {"cd", "ls", "dir", "mkdir", "rm", "cp", "mv", "echo", "python", "pip", "npm", "node", "git", "del", "powershell", "bash", "sh", "for", "while", "if", "foreach", "get-childitem", "gci"}
            first_word = code_stripped.split()[0].lower() if code_stripped.split() else ""
            has_shell_indicators = (
                first_word in shell_keywords or 
                any(indicator in code_stripped for indicator in ("\\", "/", " | ", " && ", " || "))
            )
            if has_shell_indicators:
                lang = "bash" if not IS_WINDOWS else "powershell"
            else:
                return []

    runners = []

    if lang in ("python", "py", "python3"):
        current_python = python_executable()
        runners = [(Path(current_python).name or "python", [current_python, "-c", code], None)]

    elif lang in ("bash", "sh", "shell", "zsh"):
        if IS_WINDOWS:
            runners = [
                ("PowerShell", ["powershell", "-NoProfile", "-Command", code], None),
                ("Git Bash", ["C:\\Program Files\\Git\\bin\\bash.exe", "-c", code], None),
                ("cmd", ["cmd", "/c", code], None),
            ]
        else:
            shell = lang if lang != "shell" else "bash"
            runners = [(shell, [shell, "-c", code], None),
                       ("sh",  ["sh",   "-c", code], None)]

    elif lang in ("powershell", "ps1", "ps"):
        runners = [
            ("pwsh",        ["pwsh", "-NoProfile", "-Command", code], None),
            ("PowerShell",  ["powershell", "-NoProfile", "-Command", code], None),
        ]

    elif lang in ("javascript", "js", "node", "nodejs"):
        runners = [("node", ["node", "-e", code], None)]

    elif lang in ("typescript", "ts"):
        runners = [("ts-node", ["ts-node", "-e", code], None),
                   ("npx ts-node", None, f'echo "{code}" | npx ts-node --stdin')]

    elif lang in ("ruby", "rb"):
        runners = [("ruby", ["ruby", "-e", code], None)]

    elif lang in ("perl", "pl"):
        runners = [("perl", ["perl", "-e", code], None)]

    elif lang in ("batch", "bat", "cmd"):
        runners = [("cmd", ["cmd", "/c", code], None)]

    return runners

def run_code(lang: str, code: str, silent_confirm: bool = False) -> tuple[str, bool]:
    """
    Execute code safely. Returns (output, success).
    Always confirms unless silent_confirm=True.
    Shows danger warnings for destructive operations.
    """
    code = clean_shell_code(code)
    if not code:
        return "No executable command remains after removing prompts.", False

    # CWD Safety Guardrail: Prevent deletions outside workspace
    is_deletion = any(cmd in code.lower() for cmd in ["remove-item", "rm ", "del ", "rd ", "rmdir", "rmtree", "rm -"])
    if is_deletion:
        ws_root = Path.cwd().resolve()
        # Find absolute paths
        abs_paths = re.findall(r'([A-Za-z]:\\[^ \t\n\r\f\v"\'`]+|/[^ \t\n\r\f\v"\'`]+)', code)
        for p in abs_paths:
            try:
                if not Path(p).resolve().is_relative_to(ws_root):
                    return f"Safety Violation: {p} is outside workspace ({ws_root}).", False
            except Exception:
                pass
        if ".." in code:
            return "Safety Violation: Refusing to execute path traversal deletion outside the workspace.", False

    dangerous, danger_match = is_dangerous(code)
    runners = _build_runners(lang, code)

    if not runners:
        return f"Cannot auto-run: {lang}", False

    # Preview
    preview = code.strip()[:400] + ("…" if len(code) > 400 else "")
    console.print()
    console.print(Panel(
        Syntax(preview, lang or "bash", theme="dracula", line_numbers=True),
        title=f"[bold {C['accent']}]📋 Code ({lang.upper() or 'CODE'})[/]",
        border_style=C["red"] if dangerous else C["secondary"],
        padding=(0, 1),
    ))

    if dangerous:
        console.print(f"\n  [bold {C['red']}]⚠ DESTRUCTIVE OPERATION DETECTED: `{danger_match}`[/]")

    if not silent_confirm:  # ALWAYS ask permission before executing
        if not confirm(f"Execute this {lang.upper()} code?", dangerous=dangerous):
            return "Execution cancelled.", False

    # Run
    last_err = ""
    for label, cmd_list, shell_str in runners:
        console.print(f"  [{C['dim']}]▶ Running via {label}…[/]")
        success, out, err = _try_run(cmd_list, shell_str)

        if success:
            return out or err or "(no output)", True

        last_err = err or out or "unknown error"
        console.print(f"  [{C['yellow']}]  ✗ {last_err[:100]}[/]")

    # Fallback: ask AI
    console.print(f"\n  [{C['yellow']}]All runners failed. Requesting AI fallback…[/]")
    fb = _ai_fallback(lang, code, last_err)
    if fb:
        fb_lang, fb_code = fb
        console.print(Panel(
            Syntax(fb_code.strip(), fb_lang, theme="dracula"),
            title=f"[bold {C['gold']}]🔄 AI Fallback ({fb_lang.upper()})[/]",
            border_style=C["gold"],
        ))
        if confirm(f"Run AI-generated fallback ({fb_lang.upper()})?"):
            fb_runners = _build_runners(fb_lang, fb_code)
            for _, cl, ss in fb_runners:
                success, out, err = _try_run(cl, ss)
                if success:
                    return out or err or "(no output)", True
            return f"Fallback failed: {err}", False
        return "Fallback cancelled.", False

    return f"All runners failed. Last error: {last_err}", False

def _ai_fallback(lang: str, code: str, error: str) -> Optional[tuple[str, str]]:
    try:
        msgs = [
            {"role": "system", "content": (
                "You are a cross-platform execution expert. "
                "Output ONLY a working code block with the language tag. Nothing else."
            )},
            {"role": "user", "content": (
                f"This {lang} code failed on {'Windows' if IS_WINDOWS else 'Linux/Mac'} "
                f"with error: {error}\n\nOriginal:\n```{lang}\n{code}\n```\n\n"
                f"Write a working alternative using Python stdlib or PowerShell."
            )},
        ]
        resp = ollama.chat(model=CFG["model"], messages=msgs,
                           options={"temperature": 0.1, "num_predict": 512})
        blocks = extract_code_blocks(resp.message.content or "")
        return (blocks[0][0] or "python", blocks[0][1]) if blocks else None
    except Exception:
        return None


