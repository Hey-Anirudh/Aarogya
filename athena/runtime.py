"""Runtime discovery and health checks for Athena."""
import os
import shutil
import subprocess
import sys
from pathlib import Path

try:
    import ollama
except Exception:  # pragma: no cover - handled by dependency check/doctor
    ollama = None


def quote_arg(value: str) -> str:
    """Quote a command argument for the current platform shell."""
    value = str(value)
    if not value:
        return '""'
    if os.name == "nt":
        return subprocess.list2cmdline([value])
    import shlex

    return shlex.quote(value)


def python_executable() -> str:
    """Return the interpreter that is safely running Athena right now."""
    return sys.executable or shutil.which("python3") or shutil.which("python") or "python"


def python_cmd(*args: str) -> str:
    """Build a shell command that uses Athena's current Python interpreter."""
    return " ".join([quote_arg(python_executable()), *[quote_arg(a) for a in args]])


def tool_path(name: str) -> str | None:
    """Find an executable on PATH."""
    return shutil.which(name)


def _probe(cmd: list[str], timeout: int = 5) -> tuple[bool, str]:
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        output = (result.stdout or result.stderr or "").strip()
        return result.returncode == 0, output
    except Exception as exc:
        return False, str(exc)


def doctor_report(model: str) -> list[tuple[str, str, str]]:
    """Return health rows as (check, status, detail)."""
    rows: list[tuple[str, str, str]] = []

    py = python_executable()
    py_ok = Path(py).exists()
    rows.append(("Python", "OK" if py_ok else "WARN", py))

    pip_ok, pip_out = _probe([py, "-m", "pip", "--version"])
    rows.append(("pip", "OK" if pip_ok else "WARN", pip_out or "pip is unavailable"))

    for mod in ("rich", "prompt_toolkit", "pygments", "ollama"):
        ok, detail = _probe([py, "-c", f"import {mod}; print('import ok')"])
        rows.append((f"module:{mod}", "OK" if ok else "FAIL", detail or "not importable"))

    if ollama is None:
        rows.append(("Ollama API", "FAIL", "Python package is not importable"))
    else:
        try:
            models = [m.model for m in ollama.list().models]
            if models:
                detail = f"{len(models)} model(s): {', '.join(models[:5])}"
                if model not in models:
                    rows.append(("Ollama models", "WARN", detail + f" | configured model '{model}' not found"))
                else:
                    rows.append(("Ollama models", "OK", detail))
            else:
                rows.append(("Ollama models", "WARN", "Ollama is running, but no models are pulled"))
        except Exception as exc:
            rows.append(("Ollama API", "FAIL", f"{exc}. Start with: ollama serve"))

    git = tool_path("git")
    rows.append(("git", "OK" if git else "WARN", git or "git not found on PATH"))

    node = tool_path("node")
    rows.append(("node", "OK" if node else "INFO", node or "node not found on PATH"))

    cwd = Path.cwd()
    rows.append(("workspace", "OK" if cwd.exists() else "FAIL", str(cwd)))
    return rows
