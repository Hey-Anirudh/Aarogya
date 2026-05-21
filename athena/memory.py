"""Memory persistence — facts, preferences, learned corrections."""
import json
from athena.config import MEMORY_FILE


def load_memory() -> dict:
    if MEMORY_FILE.exists():
        try:
            return json.loads(MEMORY_FILE.read_text())
        except Exception:
            pass
    return {"facts": [], "preferences": {}, "learned_corrections": []}


def save_memory(mem: dict):
    MEMORY_FILE.write_text(json.dumps(mem, indent=2))


MEMORY = load_memory()
