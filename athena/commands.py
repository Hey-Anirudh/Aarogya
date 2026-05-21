"""Command definitions, help display, export, and Ollama helpers."""
import os
import sys
import json
import shutil
import difflib
import platform
from pathlib import Path
from datetime import datetime
import ollama
from rich.table import Table
from rich.panel import Panel
from rich.syntax import Syntax
from rich.markdown import Markdown
from rich import box
from athena.config import console, C, CFG, save_config, NOTES_FILE
from athena.prompts import PERSONAS, BUILTIN_PROMPTS
from athena.memory import MEMORY, save_memory
from athena.ui import STATS, get_env_context
from athena.detection import is_dangerous, extract_code_blocks
from athena.execution import run_code, _try_run, confirm
from athena.streaming import stream_response, deep_think
from athena.files import read_file
from athena.tools import (
    backup_file, undo_last, build_tree, grep_in_files,
    confirm_action, read_file_lines, search_replace_in_file,
)
from athena.conversation import Conversation
from athena.runtime import doctor_report


def get_models() -> list[str]:
    try:
        return [m.model for m in ollama.list().models]
    except Exception:
        return []


def check_ollama() -> bool:
    try:
        ollama.list()
        return True
    except Exception:
        return False



COMMANDS = {
    "/help"              : "Show this help",
    "/new"               : "Start a new conversation",
    "/history"           : "List saved conversations",
    "/load <id>"         : "Load a conversation",
    "/save"              : "Save current conversation",
    "/clear"             : "Clear screen",
    "/models"            : "List available Ollama models",
    "/model <name>"      : "Switch model",
    "/system [prompt]"   : "Show or set system prompt",
    "/config"            : "Show current config",
    "/set <key> <val>"   : "Update a config value",
    "/run [n]"           : "Execute code block (optional: block number)",
    "/copy"              : "Copy last response to clipboard",
    "/export"            : "Export conversation to Markdown",
    "/memory"            : "Show memory",
    "/remember <fact>"   : "Add a fact to memory",
    "/forget"            : "Clear memory",
    "/think <question>"  : "Deep multi-pass chain-of-thought reasoning",
    "/summarize"         : "Summarize this conversation",
    "/stats"             : "Show session statistics",
    "/tokens"            : "Estimate token usage",
    "/persona <name>"    : "Switch persona",
    "/notes"             : "Show notes",
    "/note <text>"       : "Add a quick note",
    "/prompt <name>"     : "Load a prompt template",
    "/prompts"           : "List prompt templates",
    "/shell <cmd>"       : "Run a shell command (with permission)",
    "/file <path>"       : "Attach file content to next message",
    "/search <query>"    : "Search conversation history",
    "/diff <f1> <f2>"    : "Show diff between two files",
    "/tag <tag>"         : "Tag current conversation",
    "/version"           : "Show version info",
    "/doctor"            : "Run Athena health checks",
    # ── New CLI coding assistant commands ──
    "/tree [path] [dep]" : "Show directory tree (default depth: 3)",
    "/grep <pat> [path]" : "Search pattern across project files",
    "/cat <path>"        : "Display file contents with line numbers",
    "/head <path> [n]"   : "Show first N lines (default: 20)",
    "/tail <path> [n]"   : "Show last N lines (default: 20)",
    "/wc <path>"         : "Word/line/char count for a file",
    "/git <args>"        : "Run git command (with permission)",
    "/undo [path]"       : "Undo last file change (rollback)",
    "/cd <path>"         : "Change working directory",
    "/env"               : "Show environment info",
    "/mkdir <path>"      : "Create directory (with permission)",
    "/touch <path>"      : "Create empty file (with permission)",
    "/rm <path>"         : "Delete file/dir (with permission)",
    "/mv <src> <dst>"    : "Move/rename file (with permission)",
    "/cp <src> <dst>"    : "Copy file (with permission)",
    "/write <path>"      : "Create/overwrite file with content",
    "/replace <f> <o> <n>" : "Search & replace in file",
    "/install <pkg>"     : "Install package (pip/npm, with permission)",
    "/test [path]"       : "Run tests (pytest/npm test)",
    "/lint [path]"       : "Run linter (ruff/eslint)",
    "/fmt [path]"        : "Run formatter (black/prettier)",
    "/exec <cmd>"        : "Execute any command (with permission)",
    "/quit"              : "Exit Athena",
}


def show_help():
    table = Table(
        title=f"[bold {C['primary']}]Athena v3.2 Commands[/]",
        box=box.ROUNDED, border_style=C["dim"],
        header_style=f"bold {C['secondary']}", show_lines=True,
    )
    table.add_column("Command", style=f"bold {C['gold']}", min_width=24)
    table.add_column("Description", style=C["white"])
    for cmd, desc in COMMANDS.items():
        table.add_row(cmd, desc)
    console.print()
    console.print(table)
    console.print()
    console.print(f"  [{C['dim']}]Tips:[/]")
    console.print(f"  [{C['dim']}]• ↑/↓ arrows for history  •  Tab for completions[/]")
    console.print(f"  [{C['dim']}]• Mention filenames and Athena reads them automatically[/]")
    console.print(f"  [{C['dim']}]• Use /think for deep reasoning on complex questions[/]")
    console.print()

def show_doctor():
    table = Table(
        title=f"[bold {C['primary']}]Athena Doctor[/]",
        box=box.ROUNDED,
        border_style=C["secondary"],
    )
    table.add_column("Check", style=f"bold {C['gold']}", min_width=18)
    table.add_column("Status", width=8)
    table.add_column("Detail", style=C["white"])
    status_style = {"OK": C["green"], "WARN": C["yellow"], "FAIL": C["red"], "INFO": C["dim"]}
    for check, status, detail in doctor_report(CFG["model"]):
        table.add_row(check, f"[{status_style.get(status, C['white'])}]{status}[/]", detail)
    console.print()
    console.print(table)
    console.print()


def export_conversation(conv: Conversation, fmt: str = "md") -> str:
    lines = [
        f"# {conv.title}",
        f"> Athena CLI v3.2  |  {datetime.now().strftime('%Y-%m-%d %H:%M')}",
        f"> Model: {CFG['model']}",
        "",
    ]
    for msg in conv.messages:
        role = "**You**" if msg["role"] == "user" else "**Athena**"
        lines.append(f"### {role}")
        lines.append(msg["content"])
        lines.append("")
    content = "\n".join(lines)
    out = Path(f"athena_export_{conv.id}.{fmt}")
    out.write_text(content)
    return str(out)


