"""Tab completion for the Athena CLI."""
from pathlib import Path
from prompt_toolkit.completion import Completer, Completion
from athena.config import CFG
from athena.prompts import PERSONAS, BUILTIN_PROMPTS


def get_models() -> list[str]:
    try:
        import ollama
        return [m.model for m in ollama.list().models]
    except Exception:
        return []


ALL_COMMANDS = [
    "/help", "/new", "/history", "/load", "/save", "/clear", "/models",
    "/model", "/system", "/config", "/set", "/run", "/copy", "/export",
    "/memory", "/remember", "/forget", "/think", "/summarize", "/stats",
    "/tokens", "/persona", "/notes", "/note", "/prompt", "/prompts",
    "/shell", "/file", "/version", "/search", "/tag", "/diff", "/quit",
    # ── New CLI coding assistant commands ──
    "/tree", "/grep", "/cat", "/head", "/tail", "/wc",
    "/git", "/undo", "/cd", "/env", "/mkdir", "/touch",
    "/rm", "/mv", "/cp", "/write", "/replace",
    "/install", "/test", "/lint", "/fmt", "/exec",
]

class AthenaCompleter(Completer):
    def get_completions(self, document, complete_event):
        text = document.text_before_cursor
        word = document.get_word_before_cursor()
        if text.startswith("/"):
            cmd = text.split()[0] if text.split() else ""
            if len(text.split()) == 1 and not text.endswith(" "):
                # Complete command name
                for c in ALL_COMMANDS:
                    if c.startswith(text):
                        yield Completion(c[len(text):], start_position=0, display=c)
            elif cmd == "/model":
                for m in get_models():
                    if m.startswith(word):
                        yield Completion(m[len(word):], start_position=0)
            elif cmd == "/persona":
                for p in PERSONAS:
                    if p.startswith(word):
                        yield Completion(p[len(word):], start_position=0)
            elif cmd == "/prompt":
                for p in BUILTIN_PROMPTS:
                    if p.startswith(word):
                        yield Completion(p[len(word):], start_position=0)
        # File completion for /file
        elif text.startswith("/file "):
            partial = text[6:]
            cwd = Path.cwd()
            try:
                parent = Path(partial).parent if partial else Path(".")
                stem = Path(partial).name if partial else ""
                for entry in (cwd / parent).iterdir():
                    if entry.name.startswith(stem):
                        suffix = "/" if entry.is_dir() else ""
                        yield Completion(
                            entry.name[len(stem):] + suffix,
                            start_position=0,
                            display=entry.name + suffix,
                        )
            except Exception:
                pass


