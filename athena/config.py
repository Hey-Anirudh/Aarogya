"""
Global configuration, paths, color palette, and shared console instance.
"""
import os
import sys
import json
import platform
from pathlib import Path
from rich.console import Console

# ── Console ────────────────────────────────────────────────────────────────
console = Console(highlight=True)
IS_WINDOWS = platform.system() == "Windows"

# ── Paths ──────────────────────────────────────────────────────────────────
HOME       = Path.home()
ATHENA_DIR = HOME / ".athena"
CONV_DIR   = ATHENA_DIR / "conversations"
CONFIG_FILE = ATHENA_DIR / "config.json"
MEMORY_FILE = ATHENA_DIR / "memory.json"
NOTES_FILE  = ATHENA_DIR / "notes.md"
PROMPT_DIR  = ATHENA_DIR / "prompts"
PLAN_DIR    = ATHENA_DIR / "plans"
BACKUP_DIR  = ATHENA_DIR / "backups"

for _d in [ATHENA_DIR, CONV_DIR, PROMPT_DIR, PLAN_DIR, BACKUP_DIR]:
    _d.mkdir(parents=True, exist_ok=True)

# ── Color palette ──────────────────────────────────────────────────────────
C = {
    "primary"  : "#00D4FF",
    "secondary": "#BD93F9",
    "accent"   : "#FF79C6",
    "gold"     : "#FFB86C",
    "green"    : "#50FA7B",
    "red"      : "#FF5555",
    "dim"      : "#6272A4",
    "white"    : "#F8F8F2",
    "yellow"   : "#F1FA8C",
    "orange"   : "#FFB86C",
    "teal"     : "#8BE9FD",
}

# ── Default config ─────────────────────────────────────────────────────────
DEFAULT_CONFIG = {
    "model"            : "llama3.2",
    "temperature"      : 0.1,
    "max_tokens"       : 8192,
    "stream"           : True,
    "show_thinking"    : True,
    "auto_save"        : True,
    "context_window"   : 40,
    "auto_file_detect" : True,
    "inject_cwd"       : True,
    "auto_execute"     : False,   # Disabled: always ask permission
    "max_agent_turns"  : 3,
    "confirm_all"      : True,    # Always ask before executing
    "plan_before_act"  : False,   # Divide & Conquer is opt-in only
    "system_prompt"    : "",      # Overridden at load time
}


def load_config() -> dict:
    """Load config from disk, merging with defaults."""
    from athena.prompts import MASTER_SYSTEM_PROMPT
    cfg = DEFAULT_CONFIG.copy()
    cfg["system_prompt"] = MASTER_SYSTEM_PROMPT
    if CONFIG_FILE.exists():
        try:
            saved = json.loads(CONFIG_FILE.read_text())
            cfg.update(saved)
            if not saved.get("system_prompt"):
                cfg["system_prompt"] = MASTER_SYSTEM_PROMPT
        except Exception:
            pass
    return cfg


def save_config(cfg: dict):
    """Persist config to disk."""
    CONFIG_FILE.write_text(json.dumps(cfg, indent=2))


# ── Live config (loaded at import time) ────────────────────────────────────
CFG = load_config()
