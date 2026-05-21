"""Response rendering with Rich formatting."""
from rich.markdown import Markdown
from rich.panel import Panel
from rich.syntax import Syntax
from athena.config import console, C
from athena.detection import CODE_BLOCK_RE


def render_response(text: str, elapsed: float = 0.0):
    """Render response with full rich formatting."""
    console.print()
    parts = CODE_BLOCK_RE.split(text)
    i = 0
    while i < len(parts):
        chunk = parts[i]
        if chunk.strip():
            try:
                console.print(Markdown(chunk), style=C["white"])
            except Exception:
                console.print(chunk, style=C["white"])
        i += 1
        if i + 1 < len(parts):
            lang = parts[i] or "text"
            code = parts[i + 1]
            console.print(Panel(
                Syntax(code.strip(), lang, theme="dracula",
                       line_numbers=True, word_wrap=True),
                title=f"[bold {C['accent']}] {lang.upper() or 'CODE'} [/]",
                border_style=C["secondary"],
                padding=(0, 1),
            ))
            i += 2

    if elapsed > 0:
        words = len(text.split())
        console.print(
            f"\n  [{C['dim']}]⏱ {elapsed:.2f}s  ·  ~{int(words*1.33)} tokens  ·  {words} words[/]"
        )
    console.print()


