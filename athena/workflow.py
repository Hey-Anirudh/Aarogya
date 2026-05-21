"""Deterministic local workflows for common workspace operations."""
import re
import shutil
from difflib import SequenceMatcher
from pathlib import Path

from rich.panel import Panel
from rich.table import Table
from rich.syntax import Syntax

from athena.config import console, C
from athena.tools import backup_file, confirm_action


DELETE_WORDS = {"delete", "delte", "dlete", "dlt", "remove", "rm", "erase", "trash", "wipe"}
FILLER_WORDS = {
    "the", "a", "an", "file", "folder", "directory", "dir", "in", "this",
    "current", "here", "please", "pls", "just", "do", "it", "and", "i.e",
    "ie", "aarogya", "workspace", "every", "all", "single", "recursive",
    "recursively",
}
PROTECTED_NAMES = {".git", ".venv", ".athena-venv", "__pycache__", "athena", ".dart_tool"}


def _looks_like_portfolio_request(message: str) -> bool:
    msg = message.lower()
    verbs = ("make", "create", "build", "design", "generate")
    site_words = ("website", "site", "webpage", "page")
    return "portfolio" in msg and any(v in msg for v in verbs) and any(w in msg for w in site_words)


def _next_available_dir(base_name: str) -> Path:
    root = Path.cwd()
    candidate = root / base_name
    if not candidate.exists():
        return candidate
    for i in range(2, 100):
        candidate = root / f"{base_name}-{i}"
        if not candidate.exists():
            return candidate
    raise RuntimeError(f"Could not find an available directory name for {base_name}")


def _portfolio_files() -> dict[str, str]:
    return {
        "index.html": """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Portfolio | Creative Developer</title>
  <link rel="stylesheet" href="styles.css" />
</head>
<body>
  <header class="topbar">
    <a class="brand" href="#hero">AN</a>
    <nav aria-label="Primary navigation">
      <a href="#work">Work</a>
      <a href="#skills">Skills</a>
      <a href="#contact">Contact</a>
    </nav>
  </header>

  <main>
    <section class="hero" id="hero">
      <div class="hero-copy">
        <p class="eyebrow">Available for select projects</p>
        <h1>Designing polished digital products with code, taste, and speed.</h1>
        <p class="lede">A sharp portfolio for a developer who builds elegant interfaces, reliable systems, and memorable product experiences.</p>
        <div class="actions">
          <a class="button primary" href="#work">View Work</a>
          <a class="button ghost" href="#contact">Start a Project</a>
        </div>
      </div>
      <aside class="hero-card" aria-label="Profile summary">
        <div class="portrait">A</div>
        <p class="metric">12+ shipped builds</p>
        <p class="muted">Frontend, product engineering, automation, and responsive web experiences.</p>
      </aside>
    </section>

    <section class="section" id="work">
      <div class="section-heading">
        <p class="eyebrow">Selected Work</p>
        <h2>Projects with strong visual direction and clean execution.</h2>
      </div>
      <div class="project-grid">
        <article class="project">
          <span>01</span>
          <h3>Healthcare App</h3>
          <p>Appointment flows, user dashboards, and fast mobile-first UI for a healthcare platform.</p>
        </article>
        <article class="project">
          <span>02</span>
          <h3>Commerce Experience</h3>
          <p>Product discovery, cart interactions, and checkout screens designed for clarity and conversion.</p>
        </article>
        <article class="project">
          <span>03</span>
          <h3>Automation Tools</h3>
          <p>CLI workflows and internal tooling that turn repeated engineering tasks into one-command systems.</p>
        </article>
      </div>
    </section>

    <section class="split" id="skills">
      <div>
        <p class="eyebrow">Stack</p>
        <h2>Built for modern product work.</h2>
      </div>
      <div class="skills">
        <span>HTML</span><span>CSS</span><span>JavaScript</span><span>Flutter</span>
        <span>Node.js</span><span>Python</span><span>Firebase</span><span>UI Systems</span>
      </div>
    </section>

    <section class="contact" id="contact">
      <p class="eyebrow">Contact</p>
      <h2>Have a product idea? Let’s make it feel inevitable.</h2>
      <a class="button primary" href="mailto:hello@example.com">hello@example.com</a>
    </section>
  </main>

  <script src="script.js"></script>
</body>
</html>
""",
        "styles.css": """:root {
  color-scheme: dark;
  --bg: #090a0f;
  --panel: #121723;
  --text: #f7f0e8;
  --muted: #a9b3c4;
  --accent: #7dd3fc;
  --accent-2: #f59e0b;
  --line: rgba(255, 255, 255, 0.12);
}

* { box-sizing: border-box; }
html { scroll-behavior: smooth; }
body {
  margin: 0;
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  background:
    radial-gradient(circle at 20% 10%, rgba(125, 211, 252, 0.14), transparent 28rem),
    linear-gradient(145deg, #090a0f 0%, #10131b 45%, #16110d 100%);
  color: var(--text);
  letter-spacing: 0;
}

a { color: inherit; text-decoration: none; }

.topbar {
  position: sticky;
  top: 0;
  z-index: 10;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px min(6vw, 72px);
  backdrop-filter: blur(18px);
  background: rgba(9, 10, 15, 0.72);
  border-bottom: 1px solid var(--line);
}

.brand {
  display: grid;
  place-items: center;
  width: 42px;
  height: 42px;
  border: 1px solid var(--line);
  font-weight: 800;
}

nav { display: flex; gap: 24px; color: var(--muted); }
nav a:hover { color: var(--text); }

.hero {
  min-height: calc(100vh - 79px);
  display: grid;
  grid-template-columns: minmax(0, 1fr) 360px;
  gap: 48px;
  align-items: center;
  padding: 64px min(6vw, 72px);
}

.hero-copy { max-width: 850px; }
.eyebrow {
  margin: 0 0 16px;
  color: var(--accent);
  text-transform: uppercase;
  font-size: 0.78rem;
  font-weight: 800;
  letter-spacing: 0.08em;
}

h1, h2, h3, p { margin-top: 0; }
h1 {
  font-size: clamp(3.2rem, 9vw, 7.8rem);
  line-height: 0.92;
  margin-bottom: 28px;
  max-width: 980px;
}
h2 { font-size: clamp(2rem, 5vw, 4.2rem); line-height: 1; }
h3 { font-size: 1.4rem; }
.lede {
  max-width: 680px;
  color: var(--muted);
  font-size: 1.16rem;
  line-height: 1.7;
}

.actions { display: flex; gap: 14px; flex-wrap: wrap; margin-top: 32px; }
.button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 48px;
  padding: 0 20px;
  border: 1px solid var(--line);
  font-weight: 800;
}
.button.primary { background: var(--text); color: var(--bg); }
.button.ghost { color: var(--text); }

.hero-card, .project, .contact {
  border: 1px solid var(--line);
  background: rgba(18, 23, 35, 0.78);
}
.hero-card { padding: 28px; }
.portrait {
  display: grid;
  place-items: center;
  width: 100%;
  aspect-ratio: 1;
  margin-bottom: 22px;
  background: linear-gradient(135deg, var(--accent), var(--accent-2));
  color: #111;
  font-size: 8rem;
  font-weight: 900;
}
.metric { font-size: 1.5rem; font-weight: 900; margin-bottom: 8px; }
.muted { color: var(--muted); line-height: 1.65; }

.section, .split, .contact { padding: 84px min(6vw, 72px); }
.section-heading { max-width: 780px; margin-bottom: 34px; }
.project-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 18px;
}
.project { min-height: 250px; padding: 28px; }
.project span { color: var(--accent-2); font-weight: 900; }
.project p { color: var(--muted); line-height: 1.65; }

.split {
  display: grid;
  grid-template-columns: 0.8fr 1fr;
  gap: 36px;
  border-top: 1px solid var(--line);
  border-bottom: 1px solid var(--line);
}
.skills { display: flex; flex-wrap: wrap; gap: 12px; align-content: start; }
.skills span {
  border: 1px solid var(--line);
  padding: 12px 14px;
  color: var(--muted);
  background: rgba(255, 255, 255, 0.04);
}

.contact { margin: 0 min(6vw, 72px) 72px; }
.contact h2 { max-width: 850px; }

@media (max-width: 860px) {
  nav { gap: 14px; font-size: 0.92rem; }
  .hero, .split { grid-template-columns: 1fr; }
  .hero { padding-top: 42px; }
  .hero-card { max-width: 420px; }
  .project-grid { grid-template-columns: 1fr; }
  .contact { margin-inline: 0; }
}
""",
        "script.js": """const header = document.querySelector('.topbar');
window.addEventListener('scroll', () => {
  header.style.boxShadow = window.scrollY > 12 ? '0 16px 44px rgba(0, 0, 0, 0.28)' : 'none';
});
""",
        "README.md": """# Portfolio Website

A polished static portfolio built by Athena.

## Run

Open `index.html` in a browser, or serve this folder with any static server.
""",
    }


def _handle_portfolio_request(user_input: str) -> bool:
    if not _looks_like_portfolio_request(user_input):
        return False

    target = _next_available_dir("portfolio-website")
    files = _portfolio_files()
    table = Table(title="Website Build Plan", border_style=C["primary"])
    table.add_column("Step", width=6)
    table.add_column("Action")
    table.add_row("1", f"Create static site folder: {target.name}")
    table.add_row("2", "Write index.html, styles.css, script.js, and README.md")
    table.add_row("3", "Verify every file exists and report the local open path")
    console.print()
    console.print(table)
    console.print(Panel(
        Syntax("No package install. No create-react-app. No deployment step unless you ask for one.", "text"),
        title="[bold cyan]Execution Strategy[/]",
        border_style=C["secondary"],
    ))

    if not confirm_action(f"Create portfolio website in: {target}", dangerous=False):
        console.print(f"[{C['dim']}]Cancelled. No files changed.[/]")
        return True

    target.mkdir(parents=True, exist_ok=False)
    for name, content in files.items():
        path = target / name
        path.write_text(content, encoding="utf-8")

    expected = [target / name for name in files]
    missing = [path.name for path in expected if not path.exists() or path.stat().st_size == 0]
    if missing:
        console.print(Panel(
            "Missing or empty files after write:\n" + "\n".join(f"- {name}" for name in missing),
            title="[bold red]Build Verification Failed[/]",
            border_style=C["red"],
        ))
        return True

    console.print(Panel(
        "Created and verified:\n"
        + "\n".join(f"- {path.relative_to(Path.cwd())}" for path in expected)
        + f"\n\nOpen: {target / 'index.html'}",
        title="[bold green]Portfolio Website Ready[/]",
        border_style=C["green"],
    ))
    return True


def _normalize(text: str) -> str:
    text = text.lower().replace("=", "-")
    text = re.sub(r"[^a-z0-9]+", "", text)
    for wrong, right in {"amazone": "amazon", "delte": "delete", "dlete": "delete"}.items():
        text = text.replace(wrong, right)
    return text


def _tokens(text: str) -> list[str]:
    raw = re.findall(r"[a-zA-Z0-9_.=-]+", text.lower())
    tokens = []
    for token in raw:
        token = token.replace("=", "-").replace("amazone", "amazon")
        if token in DELETE_WORDS or token in FILLER_WORDS:
            continue
        if token == "html":
            token = ".html"
        if token:
            tokens.append(token)
    return tokens


def _looks_like_delete_request(message: str) -> bool:
    msg = message.lower()
    return any(re.search(rf"\b{re.escape(word)}\b", msg) for word in DELETE_WORDS)


def _candidate_paths(root: Path, recursive: bool) -> list[Path]:
    iterator = root.rglob("*") if recursive else root.iterdir()
    paths = []
    for path in iterator:
        rel_parts = path.relative_to(root).parts
        if any(part in PROTECTED_NAMES for part in rel_parts):
            continue
        paths.append(path)
    return paths


def _score_path(path: Path, wanted: list[str]) -> float:
    if not wanted:
        return 0.0
    name_norm = _normalize(path.name)
    stem_norm = _normalize(path.stem)
    wanted_norms = [_normalize(w) for w in wanted if _normalize(w)]
    joined = _normalize(" ".join(wanted_norms))

    score = 0.0
    for term in wanted_norms:
        if term in {name_norm, stem_norm}:
            score += 5.0
        elif term in name_norm or name_norm in term:
            score += 3.0
        else:
            score += SequenceMatcher(None, term, name_norm).ratio()
    if joined and (joined == name_norm or joined in name_norm or name_norm in joined):
        score += 4.0
    return score


def _find_delete_targets(message: str, root: Path) -> list[Path]:
    msg = message.lower()
    recursive = any(word in msg for word in ("every", "all", "single", "recursive", "recursively"))
    want_file = "file" in msg
    want_dir = not want_file and any(word in msg for word in ("folder", "directory", "dir"))
    wanted = _tokens(message)
    scored = []
    for path in _candidate_paths(root, recursive=recursive):
        if want_dir and not path.is_dir():
            continue
        if want_file and not path.is_file():
            continue
        score = _score_path(path, wanted)
        if score >= 3.0:
            scored.append((score, path))
    scored.sort(key=lambda item: (-item[0], len(item[1].parts), item[1].name.lower()))
    if recursive:
        return [p for _, p in scored]
    return [scored[0][1]] if scored else []


def _format_paths(paths: list[Path], root: Path) -> str:
    lines = []
    for path in paths:
        kind = "dir " if path.is_dir() else "file"
        try:
            display = path.relative_to(root)
        except ValueError:
            display = path
        lines.append(f"- {kind}: {display}")
    return "\n".join(lines)


def handle_local_workflow(user_input: str) -> bool:
    """Handle concrete local actions without asking the LLM to improvise."""
    if _handle_portfolio_request(user_input):
        return True

    if not _looks_like_delete_request(user_input):
        return False

    root = Path.cwd().resolve()
    targets = _find_delete_targets(user_input, root)
    if not targets:
        console.print(Panel(
            f"I checked [bold]{root}[/] and did not find a matching file or folder.\n\n"
            "Run /tree if you want to inspect the current directory.",
            title="[bold yellow]Nothing Deleted[/]",
            border_style=C["yellow"],
        ))
        return True

    table = Table(title="Delete Plan", border_style=C["red"])
    table.add_column("Type", width=8)
    table.add_column("Path")
    for target in targets:
        table.add_row("folder" if target.is_dir() else "file", str(target.relative_to(root)))
    console.print()
    console.print(table)

    if not confirm_action(
        "Delete these path(s) permanently from the workspace?\n\n" + _format_paths(targets, root),
        dangerous=True,
    ):
        console.print(f"[{C['dim']}]Cancelled. No files changed.[/]")
        return True

    deleted = []
    deleted_lines = []
    failed = []
    for target in targets:
        try:
            resolved = target.resolve()
            if not resolved.is_relative_to(root):
                failed.append((target, "outside workspace"))
                continue
            if not resolved.exists():
                continue
            if resolved.is_file():
                deleted_lines.append(f"- file: {resolved.relative_to(root)}")
                backup_file(str(resolved))
                resolved.unlink()
            elif resolved.is_dir():
                deleted_lines.append(f"- dir : {resolved.relative_to(root)}")
                shutil.rmtree(resolved)
            deleted.append(resolved)
        except Exception as exc:
            failed.append((target, str(exc)))

    still_exists = [path for path in deleted if path.exists()]
    if failed or still_exists:
        details = [f"- {path}: {error}" for path, error in failed]
        details.extend(f"- {path}: still exists after deletion attempt" for path in still_exists)
        console.print(Panel(
            "\n".join(details) or "Deletion could not be verified.",
            title="[bold red]Delete Failed[/]",
            border_style=C["red"],
        ))
        return True

    console.print(Panel(
        "Deleted and verified:\n" + "\n".join(deleted_lines),
        title="[bold green]Done[/]",
        border_style=C["green"],
    ))
    return True
