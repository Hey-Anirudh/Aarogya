"""LLM streaming, deep thinking, and clarification engine."""
import sys
import re
import json
import time
import random
from datetime import datetime
import ollama
from rich.panel import Panel
from rich.rule import Rule
from athena.config import console, C, CFG
from athena.detection import extract_code_blocks


THINKING_MSGS = [
    "Reasoning carefully…", "Reading the context…", "Planning approach…",
    "Synthesizing…", "Checking assumptions…", "Formulating…",
    "Analyzing step by step…", "Considering edge cases…",
]

def check_repetition(text: str, chunk_size: int = 100, max_repeats: int = 3) -> bool:
    """Detects if any substring of `chunk_size` is repeated `max_repeats` times sequentially."""
    if len(text) < chunk_size * max_repeats:
        return False
    last_chunk = text[-chunk_size:]
    occurrences = text.count(last_chunk)
    if occurrences >= max_repeats:
        pattern = last_chunk * max_repeats
        if pattern in text:
            return True
    return False

def stream_response(messages: list[dict], max_tokens: int = None, silent: bool = False) -> str:
    """Stream from Ollama with live output. Returns full text."""
    import random
    full_text = ""
    start = time.time()
    options = {
        "temperature": CFG["temperature"],
        "num_predict": max_tokens or CFG["max_tokens"],
    }

    if not silent:
        console.print(
            f"\n[bold {C['primary']}]◆ Athena[/]  [{C['dim']}]{datetime.now().strftime('%H:%M:%S')}[/]"
        )
        console.print(Rule(style=C["dim"] + " dim"))

    try:
        if CFG["show_thinking"] and not silent:
            with console.status(
                f"[{C['secondary']}]{random.choice(THINKING_MSGS)}[/]",
                spinner="dots", spinner_style=C["primary"],
            ):
                stream = ollama.chat(
                    model=CFG["model"], messages=messages,
                    stream=True, options=options,
                )
                first = next(stream)
                first_content = first.message.content or ""
                full_text += first_content
                time.sleep(0.25)

            sys.stdout.write(first_content)
            sys.stdout.flush()
            for chunk in stream:
                content = chunk.message.content or ""
                full_text += content
                sys.stdout.write(content)
                sys.stdout.flush()
                # Repetition Guard
                if len(full_text) > 400 and check_repetition(full_text, chunk_size=120, max_repeats=3):
                    console.print(f"\n  [bold {C['red']}]⚠ [Repetition Guard] Infinite loop streaming detected. Aborting stream.[/]")
                    break
            print()
        else:
            stream = ollama.chat(
                model=CFG["model"], messages=messages,
                stream=True, options=options,
            )
            for chunk in stream:
                content = chunk.message.content or ""
                full_text += content
                if not silent:
                    sys.stdout.write(content)
                    sys.stdout.flush()
                # Repetition Guard
                if len(full_text) > 400 and check_repetition(full_text, chunk_size=120, max_repeats=3):
                    if not silent:
                        console.print(f"\n  [bold {C['red']}]⚠ [Repetition Guard] Infinite loop streaming detected. Aborting stream.[/]")
                    break
            if not silent:
                print()

    except ollama.ResponseError as e:
        if not silent:
            console.print(f"\n[bold {C['red']}]✗ Ollama Error:[/] {e}")
        return ""
    except Exception as e:
        if not silent:
            console.print(f"\n[bold {C['red']}]✗ Error:[/] {e}")
        return ""

    if not silent:
        elapsed = time.time() - start
        console.print(Rule(style=C["dim"] + " dim"))
        words = len(full_text.split())
        console.print(
            f"  [{C['dim']}]⏱ {elapsed:.2f}s  ·  ~{int(words*1.33)} tokens  ·  {words} words[/]\n"
        )
    return full_text

# ──────────────────────────────────────────────────────────────────────────
#  DEEP THINKING MODE — multi-pass chain-of-thought
# ──────────────────────────────────────────────────────────────────────────
DEEP_THINK_SYSTEM = """You are in DEEP THINK mode — systematic, exhaustive reasoning before answering.

Structure your response EXACTLY as follows:

## 🔍 Problem Decomposition
[Break down every aspect of the question. What's being asked? What's assumed? What's ambiguous?]

## 🧠 What I Know
[Relevant facts, concepts, prior knowledge. Be specific and accurate.]

## ⚡ Reasoning Chain
Step 1: [first logical step]
Step 2: [next step, building on previous]
Step 3: [continue until conclusion]
...

## ⚠ Potential Pitfalls / Edge Cases
[What could go wrong? What am I missing? What are the failure modes?]

## 🔄 Alternative Perspectives
[At least 2 other ways to approach this problem]

## ✅ Final Answer
[Clear, definitive answer synthesizing everything above]

Be thorough. Treat this as if lives depend on getting it right."""

def deep_think(question: str, conv: "Conversation") -> str:
    """Multi-pass deep reasoning."""
    console.print(Panel(
        f"[bold {C['secondary']}]🧠 Deep Think Mode Activated[/]\n"
        f"[{C['dim']}]Multi-pass chain-of-thought reasoning…[/]",
        border_style=C["secondary"],
    ))

    # Pass 1: Initial deep think
    msgs = [
        {"role": "system", "content": DEEP_THINK_SYSTEM},
        {"role": "user",   "content": question},
    ]
    resp1 = stream_response(msgs, max_tokens=4096)

    if not resp1:
        return ""

    # Pass 2: Self-critique and refine
    console.print(f"\n  [{C['secondary']}]🔄 Self-critiquing…[/]\n")
    msgs2 = [
        {"role": "system", "content": (
            "You are a rigorous peer reviewer. Read this reasoning and:"
            "\n1. Identify any logical flaws, missing considerations, or errors"
            "\n2. If everything is correct, state that clearly"
            "\n3. Provide a refined, final synthesis"
            "\nBe harsh and accurate."
        )},
        {"role": "user", "content": f"Original question: {question}\n\nReasoning to review:\n{resp1}"},
    ]
    resp2 = stream_response(msgs2, max_tokens=2048)
    return resp1 + "\n\n---\n**Self-Review:**\n" + resp2

# ──────────────────────────────────────────────────────────────────────────
#  CLARIFICATION ENGINE — prevents misunderstandings
# ──────────────────────────────────────────────────────────────────────────
CLARIFY_SYSTEM = """You are an assistant that detects ambiguous requests.

Given a user message, determine if it needs clarification before proceeding.

Reply in JSON format ONLY:
{
  "needs_clarification": true/false,
  "ambiguities": ["list of specific ambiguities"],
  "assumed_interpretation": "what you'd assume if proceeding",
  "confidence": 0.0-1.0
}

Be conservative — only flag TRUE ambiguity, not just complexity.
Simple questions, coding tasks, and factual queries rarely need clarification."""

def check_clarification_needed(user_msg: str) -> dict:
    """Ask AI if clarification is needed before proceeding."""
    try:
        resp = ollama.chat(
            model=CFG["model"],
            messages=[
                {"role": "system", "content": CLARIFY_SYSTEM},
                {"role": "user",   "content": user_msg},
            ],
            options={"temperature": 0.1, "num_predict": 256},
        )
        text = resp.message.content or "{}"
        # Extract JSON
        json_match = re.search(r"\{.*\}", text, re.DOTALL)
        if json_match:
            return json.loads(json_match.group(0))
    except Exception:
        pass
    return {"needs_clarification": False}


