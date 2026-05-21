"""UI elements: splash screen, environment context, stats, model listing."""
import os
import sys
import time
import platform
from pathlib import Path
from datetime import datetime

from rich.text import Text
from rich.table import Table
from rich.panel import Panel
from rich.rule import Rule
from rich.align import Align
from rich import box

from athena.config import console, C, CFG, HOME


# ── Splash ─────────────────────────────────────────────────────────────────
SPLASH = r"""
    ___  _____ _   _ _____  _   _    _
   / _ \|_   _| | | | ____|| \ | |  / \
  | | | | | | | |_| |  _|  |  \| | / _ \
  | |_| | | | |  _  | |___ | |\  |/ ___ \
   \___/  |_| |_| |_|_____||_| \_/_/   \_\
"""


def print_splash():
    console.print()
    lines = SPLASH.strip("\n").split("\n")
    colors = [C["primary"], C["secondary"], C["accent"], C["gold"], C["green"]]
    for i, line in enumerate(lines):
        console.print("  " + line, style=f"bold {colors[i % len(colors)]}", markup=False)
    console.print()
    console.print(Align.center(Text(
        "⚡  Full CLI Coding Assistant · Permission-Gated · Agentic  ⚡",
        style=f"bold {C['accent']}"
    )))
    console.print(Align.center(Text(
        f"v3.2  |  Ollama  |  Model: {CFG['model']}  |  Grounded Execution",
        style=C["dim"]
    )))
    console.print()
    console.print(Rule(style=C["dim"]))
    console.print()


def get_env_context() -> str:
    """Return a string describing the current environment."""
    cwd = Path.cwd()
    lines = [
        f"OS: {platform.system()} {platform.release()} ({platform.machine()})",
        f"CWD: {cwd}",
        f"Home: {HOME}",
        f"Python: {sys.version.split()[0]}",
        f"Shell: {os.environ.get('SHELL', 'unknown')}",
    ]
    try:
        entries = list(cwd.iterdir())
        files = sorted([e for e in entries if e.is_file()], key=lambda x: x.name)
        dirs  = sorted([e for e in entries if e.is_dir()],  key=lambda x: x.name)
        if dirs:
            lines.append("Dirs:  " + "  ".join(d.name + "/" for d in dirs[:25]))
        if files:
            lines.append("Files: " + "  ".join(f.name for f in files[:40]))
    except Exception:
        pass
    return "\n".join(lines)


class SessionStats:
    """Track session statistics."""
    def __init__(self):
        self.start_time    = time.time()
        self.messages_sent = 0
        self.total_words   = 0
        self.commands_used = 0
        self.code_executed = 0
        self.models_used   = set()
        self.clarifications = 0
        self.corrections   = 0

    def show(self):
        elapsed = time.time() - self.start_time
        mins, secs = int(elapsed // 60), int(elapsed % 60)
        table = Table(
            title=f"[bold {C['primary']}]📊 Session Statistics[/]",
            box=box.ROUNDED, border_style=C["secondary"],
        )
        table.add_column("Metric", style=f"bold {C['gold']}")
        table.add_column("Value", style=C["green"])
        rows = [
            ("Duration", f"{mins}m {secs}s"),
            ("Messages", str(self.messages_sent)),
            ("Words Generated", f"{self.total_words:,}"),
            ("Commands Used", str(self.commands_used)),
            ("Code Executed", str(self.code_executed)),
            ("Clarifications", str(self.clarifications)),
            ("Self-Corrections", str(self.corrections)),
            ("Models Used", ", ".join(self.models_used) or CFG["model"]),
            ("Current Model", CFG["model"]),
            ("Context Window", str(CFG["context_window"]) + " turns"),
        ]
        for k, v in rows:
            table.add_row(k, v)
        console.print()
        console.print(table)
        console.print()


STATS = SessionStats()


def show_models():
    """Display available Ollama models."""
    import ollama
    try:
        models = [m.model for m in ollama.list().models]
    except Exception:
        console.print(f"[{C['red']}]✗ Cannot connect to Ollama. Is it running?[/]")
        return
    table = Table(
        title=f"[bold {C['primary']}]🤖 Available Models[/]",
        box=box.ROUNDED, border_style=C["secondary"],
    )
    table.add_column("#", style=C["dim"], width=4)
    table.add_column("Model", style=f"bold {C['gold']}")
    table.add_column("Status", style=C["green"])
    for i, m in enumerate(models, 1):
        active = m == CFG["model"]
        status = f"[{C['green']}]✓ Active[/]" if active else f"[{C['dim']}]Available[/]"
        table.add_row(str(i), m, status)
    console.print()
    console.print(table)
    console.print(f"\n  [{C['dim']}]Current: [bold {C['primary']}]{CFG['model']}[/][/]\n")
