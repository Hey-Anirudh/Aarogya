"""Main REPL loop for Athena CLI."""
import os
import sys
import platform
from pathlib import Path
from datetime import datetime
from prompt_toolkit import PromptSession
from prompt_toolkit.history import FileHistory
from prompt_toolkit.auto_suggest import AutoSuggestFromHistory
from prompt_toolkit.styles import Style as PTStyle
from rich.panel import Panel
from rich.table import Table
from rich.syntax import Syntax
from rich.markdown import Markdown
from rich import box
import difflib
import shutil
import ollama
from athena.config import console, C, CFG, save_config, IS_WINDOWS, ATHENA_DIR, NOTES_FILE
from athena.ui import print_splash, STATS, show_models, get_env_context
from athena.memory import MEMORY, save_memory
from athena.prompts import PERSONAS, BUILTIN_PROMPTS
from athena.conversation import Conversation
from athena.completer import AthenaCompleter
from athena.commands import get_models, check_ollama, COMMANDS, show_help, show_doctor, export_conversation
from athena.detection import extract_code_blocks, is_dangerous
from athena.execution import run_code, _try_run, confirm
from athena.streaming import stream_response, deep_think
from athena.files import read_file, auto_inject_files
from athena.tools import (
    backup_file, undo_last, build_tree, grep_in_files,
    confirm_action, read_file_lines, search_replace_in_file,
)
from athena.agents import run_agent_loop
from athena.runtime import python_cmd
from athena.workflow import handle_local_workflow


def main():
    print_splash()

    # Ollama check
    with console.status(f"[{C['secondary']}]Connecting to Ollama…[/]", spinner="dots"):
        ok = check_ollama()

    if not ok:
        console.print(Panel(
            f"[bold {C['red']}]Cannot connect to Ollama![/]\n\n"
            f"Start Ollama:  [bold {C['gold']}]ollama serve[/]\n"
            f"Pull a model:  [bold {C['gold']}]ollama pull llama3.2[/]",
            title="[bold red]Connection Error[/]", border_style="red",
        ))
        sys.exit(1)

    models = get_models()
    if CFG["model"] not in models and models:
        console.print(
            f"[{C['yellow']}]⚠ Model '{CFG['model']}' not found. "
            f"Using '{models[0]}'[/]"
        )
        CFG["model"] = models[0]
        save_config(CFG)

    console.print(
        f"  [{C['green']}]✓ Connected[/]  ·  "
        f"Model: [{C['primary']}]{CFG['model']}[/]  ·  "
        f"[{C['dim']}]Use [bold]/think <prompt>[/] for deep multi-pass reasoning · /model for options[/]"
    )
    console.print()

    conv         = Conversation()
    last_response_ref = [""]   # mutable ref for nested updates
    pending_file  = ""

    try:
        session = PromptSession(
            history=FileHistory(str(ATHENA_DIR / "prompt_history")),
            auto_suggest=AutoSuggestFromHistory(),
            completer=AthenaCompleter(),
            style=PTStyle.from_dict({
                "prompt": "bold ansicyan",
                "completion-menu.completion": "bg:#1e1e2e #cdd6f4",
                "completion-menu.completion.current": "bg:#89b4fa #1e1e2e bold",
                "auto-suggestion": "ansibrightblack italic",
            }),
            complete_while_typing=True,
            mouse_support=False,
        )
    except Exception as exc:
        console.print(Panel(
            f"[bold {C['yellow']}]Athena needs an interactive terminal.[/]\n\n"
            f"Prompt setup failed: {exc}\n\n"
            f"Open PowerShell or Windows Terminal in this folder and run:\n"
            f"[bold {C['gold']}]powershell -ExecutionPolicy Bypass -File .\\run-athena.ps1[/]",
            title="[bold yellow]Interactive Terminal Required[/]",
            border_style=C["yellow"],
        ))
        sys.exit(1)

    STATS.models_used.add(CFG["model"])

    # ── REPL ───────────────────────────────────────────────────────────────
    while True:
        try:
            turn = len([m for m in conv.messages if m["role"] == "user"]) + 1
            user_input = session.prompt(f"\n  ⚡ [{turn}] › ").strip()
        except KeyboardInterrupt:
            console.print(f"\n[{C['dim']}](Ctrl+C — /quit to exit)[/]")
            continue
        except EOFError:
            break

        if not user_input:
            continue

        # ── COMMANDS ───────────────────────────────────────────────────────
        if user_input.startswith("/"):
            parts = user_input.split(None, 2)
            cmd  = parts[0].lower()
            args = parts[1] if len(parts) > 1 else ""
            rest = parts[2] if len(parts) > 2 else ""
            STATS.commands_used += 1

            if cmd in ("/quit", "/exit", "/q"):
                conv.save()
                console.print()
                console.print(Panel(
                    f"[bold {C['primary']}]Session saved. Goodbye! ⚡[/]",
                    border_style=C["primary"],
                ))
                STATS.show()
                break

            elif cmd == "/help":
                show_help()

            elif cmd == "/new":
                conv.save()
                conv = Conversation()
                last_response_ref[0] = ""
                console.print(f"[{C['green']}]✓ New conversation.[/]")

            elif cmd == "/clear":
                os.system("cls" if IS_WINDOWS else "clear")
                print_splash()

            elif cmd == "/models":
                show_models()

            elif cmd == "/model":
                if not args:
                    console.print(f"[{C['yellow']}]Usage: /model <name>[/]")
                else:
                    available = get_models()
                    if args in available:
                        CFG["model"] = args
                        save_config(CFG)
                        STATS.models_used.add(args)
                        console.print(f"[{C['green']}]✓ Model: [bold]{args}[/][/]")
                    else:
                        console.print(f"[{C['red']}]Not found: {args}[/]")
                        console.print(f"[{C['dim']}]Available: {', '.join(available)}[/]")

            elif cmd == "/system":
                full = (args + " " + rest).strip()
                if full:
                    CFG["system_prompt"] = full
                    save_config(CFG)
                    console.print(f"[{C['green']}]✓ System prompt updated.[/]")
                else:
                    console.print(Panel(
                        CFG["system_prompt"][:800] + ("…" if len(CFG["system_prompt"]) > 800 else ""),
                        title=f"[bold {C['secondary']}]System Prompt[/]",
                        border_style=C["secondary"],
                    ))

            elif cmd == "/config":
                table = Table(
                    title=f"[bold {C['primary']}]⚙ Configuration[/]",
                    box=box.ROUNDED, border_style=C["secondary"],
                )
                table.add_column("Key", style=f"bold {C['gold']}")
                table.add_column("Value", style=C["green"])
                for k, v in CFG.items():
                    if k != "system_prompt":
                        table.add_row(k, str(v))
                console.print()
                console.print(table)
                console.print()

            elif cmd == "/set":
                if not args:
                    console.print(f"[{C['yellow']}]Usage: /set <key> <value>[/]")
                else:
                    key = args
                    val = rest
                    if key in CFG:
                        orig = CFG[key]
                        if isinstance(orig, bool):
                            CFG[key] = val.lower() in ("true", "1", "yes")
                        elif isinstance(orig, int):
                            CFG[key] = int(val)
                        elif isinstance(orig, float):
                            CFG[key] = float(val)
                        else:
                            CFG[key] = val
                        save_config(CFG)
                        console.print(f"[{C['green']}]✓ {key} = {CFG[key]}[/]")
                    else:
                        console.print(f"[{C['red']}]Unknown: {key}[/]")
                        console.print(f"[{C['dim']}]Valid keys: {', '.join(k for k in CFG if k != 'system_prompt')}[/]")

            elif cmd == "/history":
                saved = Conversation.list_saved()
                if not saved:
                    console.print(f"[{C['dim']}]No saved conversations.[/]")
                else:
                    table = Table(
                        title=f"[bold {C['primary']}]📜 Conversations[/]",
                        box=box.ROUNDED, border_style=C["secondary"],
                    )
                    table.add_column("ID", style=C["dim"], width=18)
                    table.add_column("Title", style=f"bold {C['white']}", max_width=50)
                    table.add_column("Turns", style=C["gold"], width=7)
                    table.add_column("Tags", style=C["secondary"])
                    for s in saved:
                        turns = len([m for m in s.get("messages",[]) if m["role"]=="user"])
                        tags  = ", ".join(s.get("tags", [])) or "-"
                        table.add_row(s["id"], s["title"], str(turns), tags)
                    console.print()
                    console.print(table)
                    console.print()

            elif cmd == "/load":
                if not args:
                    console.print(f"[{C['yellow']}]Usage: /load <id>[/]")
                else:
                    try:
                        conv.save()
                        conv = Conversation.load(args)
                        console.print(f"[{C['green']}]✓ Loaded: {conv.title} ({len(conv.messages)} msgs)[/]")
                    except FileNotFoundError:
                        console.print(f"[{C['red']}]Not found: {args}[/]")

            elif cmd == "/save":
                conv.save()
                console.print(f"[{C['green']}]✓ Saved: {conv.id}[/]")

            elif cmd == "/export":
                path = export_conversation(conv)
                console.print(f"[{C['green']}]✓ Exported: [bold]{path}[/][/]")

            elif cmd == "/search":
                query = (args + " " + rest).strip()
                if not query:
                    console.print(f"[{C['yellow']}]Usage: /search <query>[/]")
                else:
                    results = conv.search(query)
                    if not results:
                        console.print(f"[{C['dim']}]No results for: {query}[/]")
                    else:
                        for i, m in enumerate(results, 1):
                            role = "You" if m["role"] == "user" else "Athena"
                            preview = m["content"][:200]
                            console.print(Panel(
                                f"[{C['dim']}]{role}:[/] {preview}",
                                title=f"[{C['gold']}]Result {i}[/]",
                                border_style=C["dim"],
                            ))

            elif cmd == "/tag":
                tag = (args + " " + rest).strip()
                if tag:
                    conv.tags.append(tag)
                    conv.save()
                    console.print(f"[{C['green']}]✓ Tagged: {tag}[/]")
                else:
                    console.print(f"[{C['dim']}]Tags: {', '.join(conv.tags) or 'none'}[/]")

            elif cmd == "/run":
                if not last_response_ref[0]:
                    console.print(f"[{C['yellow']}]No response to run.[/]")
                else:
                    blocks = extract_code_blocks(last_response_ref[0])
                    if not blocks:
                        console.print(f"[{C['yellow']}]No code blocks found.[/]")
                    else:
                        idx = 0
                        if len(blocks) > 1:
                            if args and args.isdigit():
                                idx = int(args) - 1
                            else:
                                console.print(f"\n[{C['gold']}]Found {len(blocks)} blocks:[/]")
                                for i, (bl, bc) in enumerate(blocks, 1):
                                    console.print(f"  [{C['dim']}]{i}.[/] [{C['gold']}]{(bl or 'code').upper()}[/] — {bc.strip().split(chr(10))[0][:60]}")
                                try:
                                    pick = input(f"  Block (1-{len(blocks)}, Enter=last): ").strip()
                                    idx = int(pick) - 1 if pick else len(blocks) - 1
                                    idx = max(0, min(idx, len(blocks) - 1))
                                except (ValueError, KeyboardInterrupt):
                                    idx = len(blocks) - 1
                        lang, code = blocks[idx]
                        output, success = run_code(lang, code, silent_confirm=True)
                        STATS.code_executed += 1
                        border = C["green"] if success else C["red"]
                        console.print()
                        console.print(Panel(
                            output,
                            title=f"[bold {border}]▶ Output[/]",
                            border_style=border, padding=(0, 1),
                        ))

            elif cmd == "/copy":
                if not last_response_ref[0]:
                    console.print(f"[{C['yellow']}]Nothing to copy.[/]")
                else:
                    try:
                        import pyperclip
                        pyperclip.copy(last_response_ref[0])
                        console.print(f"[{C['green']}]✓ Copied to clipboard.[/]")
                    except ImportError:
                        console.print(f"[{C['yellow']}]pip install pyperclip[/]")
                    except Exception as e:
                        console.print(f"[{C['red']}]Copy failed: {e}[/]")

            elif cmd == "/think":
                question = (args + " " + rest).strip()
                if not question:
                    console.print(f"[{C['yellow']}]Usage: /think <question>[/]")
                else:
                    resp = deep_think(question, conv)
                    if resp:
                        last_response_ref[0] = resp
                        STATS.messages_sent += 1
                        STATS.total_words += len(resp.split())

            elif cmd == "/summarize":
                if not conv.messages:
                    console.print(f"[{C['yellow']}]No messages to summarize.[/]")
                else:
                    history = "\n\n".join(
                        f"{m['role'].upper()}: {m['content']}" for m in conv.messages
                    )
                    msgs = [
                        {"role": "system", "content": "Summarize this conversation in clear bullet points. Be concise and accurate."},
                        {"role": "user",   "content": history},
                    ]
                    resp = stream_response(msgs)
                    if resp:
                        last_response_ref[0] = resp

            elif cmd == "/memory":
                if not MEMORY["facts"]:
                    console.print(f"[{C['dim']}]Memory empty. Use /remember <fact>[/]")
                else:
                    console.print(Panel(
                        "\n".join(f"[{C['gold']}]•[/] {f}" for f in MEMORY["facts"]),
                        title=f"[bold {C['primary']}]🧠 Memory[/]",
                        border_style=C["secondary"],
                    ))

            elif cmd == "/remember":
                fact = (args + " " + rest).strip()
                if fact:
                    MEMORY["facts"].append(fact)
                    save_memory(MEMORY)
                    console.print(f"[{C['green']}]✓ Remembered: {fact}[/]")
                else:
                    console.print(f"[{C['yellow']}]Usage: /remember <fact>[/]")

            elif cmd == "/forget":
                MEMORY["facts"] = []
                MEMORY["preferences"] = {}
                MEMORY["learned_corrections"] = []
                save_memory(MEMORY)
                console.print(f"[{C['green']}]✓ Memory cleared.[/]")

            elif cmd == "/stats":
                STATS.show()

            elif cmd == "/persona":
                name = args.lower()
                if name in PERSONAS:
                    CFG["system_prompt"] = PERSONAS[name]
                    save_config(CFG)
                    console.print(f"[{C['green']}]✓ Persona: [bold]{name}[/][/]")
                else:
                    names = ", ".join(PERSONAS.keys())
                    console.print(f"[{C['yellow']}]Personas: {names}[/]")

            elif cmd == "/note":
                text = (args + " " + rest).strip()
                if text:
                    with open(NOTES_FILE, "a") as f:
                        f.write(f"\n- [{datetime.now().strftime('%Y-%m-%d %H:%M')}] {text}")
                    console.print(f"[{C['green']}]✓ Note saved.[/]")
                else:
                    console.print(f"[{C['yellow']}]Usage: /note <text>[/]")

            elif cmd == "/notes":
                if NOTES_FILE.exists() and NOTES_FILE.stat().st_size > 0:
                    console.print(Markdown(NOTES_FILE.read_text()))
                else:
                    console.print(f"[{C['dim']}]No notes. Use /note <text>[/]")

            elif cmd == "/shell":
                shell_cmd = (args + " " + rest).strip()
                if not shell_cmd:
                    console.print(f"[{C['yellow']}]Usage: /shell <command>[/]")
                else:
                    console.print(Panel(
                        f"[{C['gold']}]$ {shell_cmd}[/]",
                        title=f"[bold {C['accent']}]Shell Command[/]",
                        border_style=C["secondary"],
                    ))
                    dangerous, _ = is_dangerous(shell_cmd)
                    if not confirm(f"Run: {shell_cmd}", dangerous=dangerous):
                        console.print(f"[{C['dim']}]Cancelled.[/]")
                    else:
                        ok, out, err = _try_run(shell_str=shell_cmd)
                        if out:
                            console.print(Panel(out, title=f"[bold {C['green']}]Output[/]",
                                                border_style=C["green"]))
                        if err:
                            console.print(Panel(err, title=f"[bold {C['yellow']}]Stderr[/]",
                                                border_style=C["yellow"]))
                        if not out and not err:
                            console.print(f"  [{C['dim']}](no output)[/]")

            elif cmd == "/file":
                path = args.strip()
                if path:
                    pending_file = read_file(path)
                    fname = Path(path).name
                    if pending_file.startswith("[Error"):
                        console.print(f"[{C['red']}]{pending_file}[/]")
                        pending_file = ""
                    else:
                        console.print(f"[{C['green']}]✓ Attached: [bold]{fname}[/] (included in next message)[/]")
                else:
                    console.print(f"[{C['yellow']}]Usage: /file <path>[/]")

            elif cmd == "/diff":
                f1, f2 = args.strip(), rest.strip()
                if not f1 or not f2:
                    console.print(f"[{C['yellow']}]Usage: /diff <file1> <file2>[/]")
                else:
                    try:
                        t1 = Path(f1).read_text(errors="replace").splitlines(keepends=True)
                        t2 = Path(f2).read_text(errors="replace").splitlines(keepends=True)
                        diff = "".join(difflib.unified_diff(t1, t2, fromfile=f1, tofile=f2))
                        if diff:
                            console.print(Syntax(diff, "diff", theme="dracula"))
                        else:
                            console.print(f"[{C['green']}]Files are identical.[/]")
                    except Exception as e:
                        console.print(f"[{C['red']}]Diff failed: {e}[/]")

            elif cmd == "/prompts":
                table = Table(
                    title=f"[bold {C['primary']}]📝 Templates[/]",
                    box=box.ROUNDED, border_style=C["secondary"],
                )
                table.add_column("Name", style=f"bold {C['gold']}")
                table.add_column("Preview", style=C["dim"])
                for k, v in BUILTIN_PROMPTS.items():
                    table.add_row(k, v[:65] + "…")
                console.print()
                console.print(table)
                console.print()

            elif cmd == "/prompt":
                name = args.strip()
                if name in BUILTIN_PROMPTS:
                    template = BUILTIN_PROMPTS[name]
                    console.print(Panel(
                        f"[{C['white']}]{template}[/]",
                        title=f"[bold {C['gold']}]Template: {name}[/]",
                        border_style=C["secondary"],
                    ))
                    console.print(f"[{C['dim']}]Fill {{placeholders}} and send as next message.[/]")
                else:
                    console.print(f"[{C['yellow']}]Not found: {name}. Use /prompts[/]")

            elif cmd == "/tokens":
                total = sum(len(m["content"]) for m in conv.messages)
                console.print(f"[{C['gold']}]~{int(total/4):,} tokens in context[/]")

            elif cmd == "/version":
                console.print(Panel(
                    f"[bold {C['primary']}]Athena CLI v3.2[/]\n"
                    f"[{C['dim']}]Sonnet-level intelligence · Agentic · Self-correcting[/]\n"
                    f"[{C['secondary']}]Ollama · Model: {CFG['model']}[/]\n"
                    f"[{C['dim']}]Python {sys.version.split()[0]} · {platform.system()}[/]",
                    border_style=C["primary"],
                ))

            # ── NEW CLI CODING ASSISTANT COMMANDS ──────────────────────────

            elif cmd == "/doctor":
                show_doctor()

            elif cmd == "/tree":
                tree_path = args.strip() or "."
                depth = 3
                if rest and rest.strip().isdigit():
                    depth = int(rest.strip())
                tree_out = build_tree(tree_path, depth)
                console.print()
                console.print(Panel(
                    tree_out,
                    title=f"[bold {C['primary']}]🌳 Directory Tree[/]",
                    border_style=C["secondary"], padding=(0, 1),
                ))
                console.print()

            elif cmd == "/grep":
                pattern = args.strip()
                search_path = rest.strip() or "."
                if not pattern:
                    console.print(f"[{C['yellow']}]Usage: /grep <pattern> [path][/]")
                else:
                    with console.status(f"[{C['secondary']}]Searching for '{pattern}'…[/]", spinner="dots"):
                        results = grep_in_files(pattern, search_path)
                    if not results:
                        console.print(f"[{C['dim']}]No matches for: {pattern}[/]")
                    else:
                        table = Table(
                            title=f"[bold {C['primary']}]🔍 Grep: {pattern} ({len(results)} matches)[/]",
                            box=box.ROUNDED, border_style=C["secondary"],
                        )
                        table.add_column("File", style=f"bold {C['gold']}", max_width=40)
                        table.add_column("Line", style=C["teal"], width=6)
                        table.add_column("Content", style=C["white"])
                        for fp, ln, txt in results[:50]:
                            table.add_row(fp, str(ln), txt)
                        console.print()
                        console.print(table)
                        if len(results) > 50:
                            console.print(f"  [{C['dim']}]… and {len(results)-50} more matches[/]")
                        console.print()

            elif cmd == "/cat":
                path = args.strip()
                if not path:
                    console.print(f"[{C['yellow']}]Usage: /cat <path>[/]")
                else:
                    content = read_file_lines(path)
                    if content.startswith("[Error"):
                        console.print(f"[{C['red']}]{content}[/]")
                    else:
                        console.print()
                        console.print(Panel(content, title=f"[bold {C['gold']}]{Path(path).name}[/]",
                                           border_style=C["secondary"], padding=(0, 1)))
                        console.print()

            elif cmd == "/head":
                path = args.strip()
                n = 20
                if rest and rest.strip().isdigit():
                    n = int(rest.strip())
                if not path:
                    console.print(f"[{C['yellow']}]Usage: /head <path> [n][/]")
                else:
                    content = read_file_lines(path, start=1, end=n)
                    if content.startswith("[Error"):
                        console.print(f"[{C['red']}]{content}[/]")
                    else:
                        console.print(Panel(content, title=f"[bold {C['gold']}]{Path(path).name} (first {n} lines)[/]",
                                           border_style=C["secondary"], padding=(0, 1)))

            elif cmd == "/tail":
                path = args.strip()
                n = 20
                if rest and rest.strip().isdigit():
                    n = int(rest.strip())
                if not path:
                    console.print(f"[{C['yellow']}]Usage: /tail <path> [n][/]")
                else:
                    p = Path(path).expanduser()
                    if not p.exists():
                        p = Path.cwd() / path
                    if p.exists():
                        total = len(p.read_text(encoding='utf-8', errors='replace').splitlines())
                        content = read_file_lines(path, start=max(1, total - n + 1), end=total)
                        console.print(Panel(content, title=f"[bold {C['gold']}]{p.name} (last {n} lines)[/]",
                                           border_style=C["secondary"], padding=(0, 1)))
                    else:
                        console.print(f"[{C['red']}]File not found: {path}[/]")

            elif cmd == "/wc":
                path = args.strip()
                if not path:
                    console.print(f"[{C['yellow']}]Usage: /wc <path>[/]")
                else:
                    p = Path(path).expanduser()
                    if not p.exists():
                        p = Path.cwd() / path
                    if p.exists():
                        try:
                            text = p.read_text(encoding='utf-8', errors='replace')
                            lines = len(text.splitlines())
                            words = len(text.split())
                            chars = len(text)
                            sz = p.stat().st_size
                            console.print(f"  [{C['gold']}]{p.name}:[/]  {lines:,} lines  ·  {words:,} words  ·  {chars:,} chars  ·  {sz/1024:.1f}KB")
                        except Exception as e:
                            console.print(f"[{C['red']}]Error: {e}[/]")
                    else:
                        console.print(f"[{C['red']}]File not found: {path}[/]")

            elif cmd == "/git":
                git_args = (args + " " + rest).strip()
                if not git_args:
                    console.print(f"[{C['yellow']}]Usage: /git <command>[/]")
                else:
                    git_cmd = f"git {git_args}"
                    dangerous_git = any(w in git_args for w in ["push -f", "push --force", "reset --hard", "clean -fd", "branch -D", "rm", "stash drop"])
                    if not confirm_action(f"Run: {git_cmd}", dangerous=dangerous_git):
                        console.print(f"[{C['dim']}]Cancelled.[/]")
                    else:
                        ok, out, err = _try_run(shell_str=git_cmd, timeout=60)
                        if out:
                            console.print(Panel(out, title=f"[bold {C['green']}]git output[/]", border_style=C["green"]))
                        if err:
                            console.print(Panel(err, title=f"[bold {C['yellow']}]stderr[/]", border_style=C["yellow"]))
                        if not out and not err:
                            console.print(f"  [{C['dim']}](no output)[/]")

            elif cmd == "/undo":
                target = args.strip() or None
                ok, msg = undo_last(target)
                style = C["green"] if ok else C["yellow"]
                console.print(f"[{style}]{msg}[/]")

            elif cmd == "/cd":
                new_dir = (args + " " + rest).strip()
                if not new_dir:
                    console.print(f"  [{C['gold']}]CWD: {Path.cwd()}[/]")
                else:
                    target = Path(new_dir).expanduser().resolve()
                    if target.exists() and target.is_dir():
                        os.chdir(target)
                        console.print(f"[{C['green']}]✓ CWD: {target}[/]")
                    else:
                        console.print(f"[{C['red']}]Not a directory: {new_dir}[/]")

            elif cmd == "/env":
                env_text = get_env_context()
                console.print(Panel(env_text, title=f"[bold {C['primary']}]🖥 Environment[/]",
                                   border_style=C["secondary"], padding=(0, 1)))

            elif cmd == "/mkdir":
                dir_path = args.strip()
                if not dir_path:
                    console.print(f"[{C['yellow']}]Usage: /mkdir <path>[/]")
                elif confirm_action(f"Create directory: {dir_path}"):
                    try:
                        Path(dir_path).mkdir(parents=True, exist_ok=True)
                        console.print(f"[{C['green']}]✓ Created: {dir_path}[/]")
                    except Exception as e:
                        console.print(f"[{C['red']}]Error: {e}[/]")
                else:
                    console.print(f"[{C['dim']}]Cancelled.[/]")

            elif cmd == "/touch":
                file_path = args.strip()
                if not file_path:
                    console.print(f"[{C['yellow']}]Usage: /touch <path>[/]")
                elif confirm_action(f"Create file: {file_path}"):
                    try:
                        p = Path(file_path)
                        p.parent.mkdir(parents=True, exist_ok=True)
                        p.touch()
                        console.print(f"[{C['green']}]✓ Created: {file_path}[/]")
                    except Exception as e:
                        console.print(f"[{C['red']}]Error: {e}[/]")
                else:
                    console.print(f"[{C['dim']}]Cancelled.[/]")

            elif cmd == "/rm":
                target_path = args.strip()
                if not target_path:
                    console.print(f"[{C['yellow']}]Usage: /rm <path>[/]")
                else:
                    p = Path(target_path).resolve()
                    if not p.exists():
                        console.print(f"[{C['red']}]Not found: {target_path}[/]")
                    elif confirm_action(f"DELETE: {p}", dangerous=True):
                        try:
                            if p.is_file():
                                backup_file(str(p))
                                p.unlink()
                            elif p.is_dir():
                                shutil.rmtree(p)
                            console.print(f"[{C['green']}]✓ Deleted: {p}[/]")
                        except Exception as e:
                            console.print(f"[{C['red']}]Error: {e}[/]")
                    else:
                        console.print(f"[{C['dim']}]Cancelled.[/]")

            elif cmd == "/mv":
                src = args.strip()
                dst = rest.strip()
                if not src or not dst:
                    console.print(f"[{C['yellow']}]Usage: /mv <source> <destination>[/]")
                elif confirm_action(f"Move: {src} → {dst}"):
                    try:
                        backup_file(src)
                        shutil.move(src, dst)
                        console.print(f"[{C['green']}]✓ Moved: {src} → {dst}[/]")
                    except Exception as e:
                        console.print(f"[{C['red']}]Error: {e}[/]")
                else:
                    console.print(f"[{C['dim']}]Cancelled.[/]")

            elif cmd == "/cp":
                src = args.strip()
                dst = rest.strip()
                if not src or not dst:
                    console.print(f"[{C['yellow']}]Usage: /cp <source> <destination>[/]")
                elif confirm_action(f"Copy: {src} → {dst}"):
                    try:
                        if Path(src).is_dir():
                            shutil.copytree(src, dst)
                        else:
                            shutil.copy2(src, dst)
                        console.print(f"[{C['green']}]✓ Copied: {src} → {dst}[/]")
                    except Exception as e:
                        console.print(f"[{C['red']}]Error: {e}[/]")
                else:
                    console.print(f"[{C['dim']}]Cancelled.[/]")

            elif cmd == "/write":
                file_path = args.strip()
                if not file_path:
                    console.print(f"[{C['yellow']}]Usage: /write <path>[/]")
                    console.print(f"[{C['dim']}]Then type content. End with a line containing only 'EOF'[/]")
                else:
                    console.print(f"[{C['teal']}]Enter content for {file_path} (end with EOF on its own line):[/]")
                    lines_buf = []
                    try:
                        while True:
                            line = input()
                            if line.strip() == "EOF":
                                break
                            lines_buf.append(line)
                    except (KeyboardInterrupt, EOFError):
                        console.print(f"[{C['dim']}]Cancelled.[/]")
                        lines_buf = []
                    if lines_buf:
                        content = "\n".join(lines_buf) + "\n"
                        p = Path(file_path)
                        action = "Overwrite" if p.exists() else "Create"
                        if confirm_action(f"{action}: {file_path} ({len(lines_buf)} lines)"):
                            if p.exists():
                                backup_file(str(p))
                            p.parent.mkdir(parents=True, exist_ok=True)
                            p.write_text(content, encoding='utf-8')
                            console.print(f"[{C['green']}]✓ Written: {file_path} ({len(lines_buf)} lines)[/]")
                        else:
                            console.print(f"[{C['dim']}]Cancelled.[/]")

            elif cmd == "/replace":
                file_path = args.strip()
                # rest contains "old_text new_text" — use first and second quoted or space-separated tokens
                if not file_path or not rest.strip():
                    console.print(f"[{C['yellow']}]Usage: /replace <file> <old_text> <new_text>[/]")
                    console.print(f"[{C['dim']}]Tip: Use quotes for multi-word patterns[/]")
                else:
                    # Parse rest into old and new (split on first unquoted space)
                    tokens = rest.strip().split(None, 1)
                    if len(tokens) < 2:
                        console.print(f"[{C['yellow']}]Need both old and new text. Usage: /replace <file> <old> <new>[/]")
                    else:
                        old_text, new_text = tokens[0], tokens[1]
                        if confirm_action(f"Replace in {file_path}:\n  OLD: {old_text}\n  NEW: {new_text}"):
                            ok, msg = search_replace_in_file(file_path, old_text, new_text)
                            style = C["green"] if ok else C["red"]
                            console.print(f"[{style}]{msg}[/]")
                        else:
                            console.print(f"[{C['dim']}]Cancelled.[/]")

            elif cmd == "/install":
                pkg = (args + " " + rest).strip()
                if not pkg:
                    console.print(f"[{C['yellow']}]Usage: /install <package>[/]")
                else:
                    # Detect package manager
                    if (Path.cwd() / "package.json").exists():
                        install_cmd = f"npm install {pkg}"
                    else:
                        install_cmd = python_cmd("-m", "pip", "install", pkg)
                    if confirm_action(f"Install: {install_cmd}"):
                        console.print(f"  [{C['dim']}]Running: {install_cmd}[/]")
                        ok, out, err = _try_run(shell_str=install_cmd, timeout=120)
                        if ok:
                            console.print(f"[{C['green']}]✓ Installed: {pkg}[/]")
                            if out:
                                console.print(f"[{C['dim']}]{out[-300:]}[/]")
                        else:
                            console.print(f"[{C['red']}]Failed: {err or out}[/]")
                    else:
                        console.print(f"[{C['dim']}]Cancelled.[/]")

            elif cmd == "/test":
                test_path = (args + " " + rest).strip()
                if (Path.cwd() / "package.json").exists():
                    test_cmd = "npm test"
                elif (Path.cwd() / "pytest.ini").exists() or (Path.cwd() / "pyproject.toml").exists() or (Path.cwd() / "setup.py").exists():
                    test_cmd = python_cmd("-m", "pytest", test_path) if test_path else python_cmd("-m", "pytest")
                else:
                    test_cmd = python_cmd("-m", "pytest", test_path) if test_path else python_cmd("-m", "pytest")
                if confirm_action(f"Run tests: {test_cmd}"):
                    ok, out, err = _try_run(shell_str=test_cmd, timeout=120)
                    output_text = out or err or "(no output)"
                    border = C["green"] if ok else C["red"]
                    console.print(Panel(output_text, title=f"[bold {border}]Test Results[/]",
                                       border_style=border, padding=(0, 1)))
                else:
                    console.print(f"[{C['dim']}]Cancelled.[/]")

            elif cmd == "/lint":
                lint_path = (args + " " + rest).strip() or "."
                if (Path.cwd() / "package.json").exists():
                    lint_cmd = f"npx eslint {lint_path}"
                else:
                    lint_cmd = python_cmd("-m", "ruff", "check", lint_path)
                if confirm_action(f"Run linter: {lint_cmd}"):
                    ok, out, err = _try_run(shell_str=lint_cmd, timeout=60)
                    output_text = out or err or "No issues found ✓"
                    border = C["green"] if ok else C["yellow"]
                    console.print(Panel(output_text, title=f"[bold {border}]Lint Results[/]",
                                       border_style=border, padding=(0, 1)))
                else:
                    console.print(f"[{C['dim']}]Cancelled.[/]")

            elif cmd == "/fmt":
                fmt_path = (args + " " + rest).strip() or "."
                if (Path.cwd() / "package.json").exists():
                    fmt_cmd = f"npx prettier --write {fmt_path}"
                else:
                    fmt_cmd = python_cmd("-m", "black", fmt_path)
                if confirm_action(f"Run formatter: {fmt_cmd}"):
                    backup_file(fmt_path) if Path(fmt_path).is_file() else None
                    ok, out, err = _try_run(shell_str=fmt_cmd, timeout=60)
                    output_text = out or err or "Formatted ✓"
                    border = C["green"] if ok else C["yellow"]
                    console.print(Panel(output_text, title=f"[bold {border}]Format Results[/]",
                                       border_style=border, padding=(0, 1)))
                else:
                    console.print(f"[{C['dim']}]Cancelled.[/]")

            elif cmd == "/exec":
                exec_cmd = (args + " " + rest).strip()
                if not exec_cmd:
                    console.print(f"[{C['yellow']}]Usage: /exec <command>[/]")
                else:
                    dangerous, _ = is_dangerous(exec_cmd)
                    if confirm_action(f"Execute: {exec_cmd}", dangerous=dangerous):
                        ok, out, err = _try_run(shell_str=exec_cmd, timeout=60)
                        if out:
                            console.print(Panel(out, title=f"[bold {C['green']}]Output[/]", border_style=C["green"]))
                        if err:
                            console.print(Panel(err, title=f"[bold {C['yellow']}]Stderr[/]", border_style=C["yellow"]))
                        if not out and not err:
                            console.print(f"  [{C['dim']}](no output)[/]")
                    else:
                        console.print(f"[{C['dim']}]Cancelled.[/]")

            else:
                console.print(f"[{C['yellow']}]Unknown: {cmd}. Type /help[/]")

        # ── NORMAL MESSAGE ─────────────────────────────────────────────────
        else:
            if handle_local_workflow(user_input):
                continue

            # Prepend pending file
            if pending_file:
                user_input = user_input + "\n\n" + pending_file
                pending_file = ""

            # Auto-detect and inject file references
            augmented, auto_files = auto_inject_files(user_input)
            if auto_files:
                console.print(f"  [{C['green']}]📎 Auto-read: [bold]{', '.join(auto_files)}[/][/]")
                user_input = augmented

            # Add to conversation
            conv.add("user", user_input)
            STATS.messages_sent += 1

            # Run agentic loop
            run_agent_loop(conv, user_input, last_response_ref)

    console.print()


if __name__ == "__main__":
    main()
