"""Agentic execution loop and Divide & Conquer orchestrator."""
import re
import json
import time
import ollama
from rich.panel import Panel
from rich.table import Table
from rich.syntax import Syntax
from rich.rule import Rule
from rich import box
from athena.config import console, C, CFG
from athena.ui import STATS
from athena.detection import extract_code_blocks, extract_commands_from_text, clean_shell_code
from athena.execution import run_code, _build_runners, confirm
from athena.streaming import stream_response, check_clarification_needed
from athena.conversation import Conversation


def render_task_board(goal: str, subtasks: list[dict], current_id: int):
    """
    Renders a stunning, premium Rich task board showing the sequential status
    of all subproblems in our Divide & Conquer plan.
    """
    table = Table(box=box.SIMPLE, show_header=False, expand=True)
    table.add_column("Status", width=4, justify="center")
    table.add_column("Task", style="bold")
    
    for task in subtasks:
        tid = task.get("id", 0)
        title = task.get("title", "Untitled")
        desc = task.get("description", "")
        status = task.get("status", "pending")
        
        if status == "completed":
            icon = f"[bold {C['green']}]✓[/]"
            style = f"dim {C['green']}"
            text = f"[{style}]{title} — {desc}[/]"
        elif status == "running" or tid == current_id:
            icon = f"[bold {C['primary']}]▶[/]"
            style = f"bold {C['white']}"
            text = f"[{style}]{title}[/] [bold {C['accent']}]({desc})[/]"
        elif status == "failed":
            icon = f"[bold {C['red']}]✗[/]"
            style = f"bold {C['red']}"
            text = f"[{style}]{title} — {desc}[/]"
        else:
            icon = f"[{C['dim']}]·[/]"
            style = C["dim"]
            text = f"[{style}]{title} — {desc}[/]"
            
        table.add_row(icon, text)
        
    panel = Panel(
        table,
        title=f"[bold {C['secondary']}]📋 SUBTASK TRACKER: {goal[:60] + '...' if len(goal)>60 else goal}[/]",
        border_style=C["primary"],
        padding=(0, 1)
    )
    console.print()
    console.print(panel)
    console.print()

def confirm_dc_plan(goal: str, subtasks: list[dict]) -> bool:
    """
    Prompts the user to confirm the generated Divide & Conquer plan.
    """
    if not CFG.get("confirm_all", True):
        return True
    render_task_board(goal, subtasks, current_id=1)
    console.print(f"  [{C['yellow']}]Proceed with this Divide & Conquer execution plan? ([bold green]y[/bold green] / [bold red]n[/bold red])[/]")
    try:
        ans = input("  › ").strip().lower()
    except (KeyboardInterrupt, EOFError):
        ans = "n"
    return ans in ("y", "yes")

def generate_divide_and_conquer_plan(user_input: str) -> list[dict]:
    """
    Asks Ollama to analyze the overall request and return a structured JSON array
    decomposing it into 2 to 6 separate subproblems.
    """
    prompt = f"""Decompose the following user request into 2 to 6 separate, logical, sequential subproblems (subtasks).
Each subtask must have a clear objective and exact success criteria.

⚠️ CRITICAL RULE: If the request is simple, straightforward, or a read-only request (e.g. listing files, reading a single file, general questions, explaining code, running a single git command), you MUST return an empty JSON array `[]` to signal that no planning is needed.

Output your plan as a raw JSON array of objects. Do not write any conversational filler, markdown formatting, or explanation.
JSON format:
[
  {{
    "id": 1,
    "title": "Short descriptive title of the subproblem",
    "description": "Specific action to take relative to the workspace, e.g. 'Write a Python script database.py to create the schema.'",
    "success_criteria": "The file database.py exists and runs successfully with no errors."
  }},
  ...
]

Request: {user_input}"""

    try:
        resp = ollama.chat(
            model=CFG["model"],
            messages=[
                {"role": "system", "content": "You are a senior system architect. Output ONLY valid JSON arrays. Do not wrap in markdown or add text."},
                {"role": "user", "content": prompt}
            ],
            options={"temperature": 0.1, "num_predict": 1024}
        )
        content = resp.message.content or ""
        
        # Clean potential markdown wrapping
        if "```" in content:
            blocks = re.findall(r"```(?:json)?\n(.*?)```", content, re.DOTALL)
            if blocks:
                content = blocks[0]
        
        # Try finding [ ... ] first
        json_match = re.search(r'\[\s*\{.*\}\s*\]', content, re.DOTALL)
        if json_match:
            content = json_match.group(0)
            
        data = json.loads(content.strip())
        if isinstance(data, list) and len(data) >= 2:
            for i, t in enumerate(data, 1):
                t["id"] = i
                t["status"] = "pending"
                if "title" not in t:
                    t["title"] = f"Subtask {i}"
                if "description" not in t:
                    t["description"] = "No description provided."
                if "success_criteria" not in t:
                    t["success_criteria"] = "No success criteria defined."
            return data
    except Exception:
        pass
    return []

def run_subtask(task: dict, subtasks: list[dict], user_input: str, total_tasks: int) -> tuple[bool, str]:
    """
    Executes a single subtask autonomously in a sandboxed conversation context.
    Only displays status spinners, proposed code blocks, and output results.
    """
    task_id = task["id"]
    task["status"] = "running"
    
    sub_conv = Conversation()
    sub_conv.tags = []
    
    sub_conv.add("user", (
        f"=== DIVIDE & CONQUER EXECUTIVE ORCHESTRATOR ===\n"
        f"OVERALL GOAL: {user_input}\n"
        f"CURRENT SUBTASK: {task['title']} ({task_id} of {total_tasks})\n"
        f"OBJECTIVE: {task['description']}\n"
        f"SUCCESS CRITERIA: {task['success_criteria']}\n\n"
        f"TASK BOARD STATUS:\n" + 
        "\n".join(f"- {t['title']} (Status: {t['status']})" for t in subtasks) + "\n\n"
        f"Focus EXCLUSIVELY on completing this subtask. Generate plans and code blocks to achieve this objective.\n\n"
        f"⚠️ MANDATORY FILE WRITING PROTOCOL:\n"
        f"If the objective of this subtask requires creating, writing, editing, or saving a file, "
        f"you MUST output a Python code block or a Shell command that ACTUALLY writes the content to disk.\n"
        f"Do NOT just output a raw code block representing the file contents. If you output a raw code block without "
        f"file-writing code (like 'with open(filename, \"w\")'), it will just execute in memory and NOT be saved!\n"
        f"Example to write code to 'file.py':\n"
        f"```python\n"
        f"with open(\"file.py\", \"w\", encoding=\"utf-8\") as f:\n"
        f"    f.write('''# Your actual code goes here...\\n''')\n"
        f"```\n\n"
        f"When you are absolutely finished and verified, you MUST reply with 'SUBTASK_COMPLETE' to signal the orchestrator to advance."
    ))
    
    task_turns = 6
    last_success = False
    summary_notes = []
    
    for turn in range(task_turns):
        msgs = sub_conv.get_messages_for_api()
        
        # Display a clean, dynamic status spinner instead of streaming pages of planning text
        with console.status(
            f"[{C['secondary']}]Athena: Working on Step {turn+1} of Subtask {task_id} ([bold]{task['title']}[/])…[/]",
            spinner="dots", spinner_style=C["primary"]
        ):
            resp = stream_response(msgs, silent=True)
            
        if not resp:
            break
            
        sub_conv.add("assistant", resp)
        STATS.total_words += len(resp.split())
        
        # Detect code blocks
        blocks = extract_code_blocks(resp)
            
        if not blocks:
            if "SUBTASK_COMPLETE" in resp:
                last_success = True
                break
            sub_conv.add("user", (
                "No executable code blocks detected. If this subtask is complete, "
                "please output 'SUBTASK_COMPLETE'. Otherwise, please provide "
                "the necessary code block or shell command."
            ))
            continue
            
        # Run first executable block
        executable_block = None
        for l, c in blocks:
            c_clean = clean_shell_code(c)
            if not c_clean:
                continue
            runners = _build_runners(l, c_clean)
            if runners:
                executable_block = (l, c)
                break
                
        if not executable_block:
            if "SUBTASK_COMPLETE" in resp:
                last_success = True
                break
            sub_conv.add("user", (
                "The code block provided is not executable. Please write "
                "a valid Python or Shell code block, or reply 'SUBTASK_COMPLETE' if done."
            ))
            continue
            
        lang, code = executable_block
        
        # Ask the user for explicit permissions to execute this command
        console.print(f"  [{C['yellow']}]🔐 Permission Request:[/] Athena wants to execute a script for Subtask {task_id}:")
        console.print(Panel(
            Syntax(code.strip(), lang, theme="monokai", line_numbers=True),
            title=f"[bold {C['primary']}]📋 Proposed Code ({lang.upper()})[/]",
            border_style=C["primary"],
            padding=(0, 1),
            expand=False
        ))
        
        console.print(f"  Approve execution? ([bold green]y[/bold green] = Yes / [bold red]n[/bold red] = No / Enter = Yes)")
        try:
            ans = input("  › ").strip().lower()
        except (KeyboardInterrupt, EOFError):
            ans = "n"
            
        if ans not in ("", "y", "yes"):
            console.print(f"  [{C['red']}]✗ Execution rejected by user.[/]\n")
            sub_conv.add("user", "User rejected the execution of this code block. Please propose an alternative approach or ask for clarification.")
            continue
            
        console.print(f"  [{C['dim']}]Executing script…[/]")
        output, success = run_code(lang, code, silent_confirm=True)
        STATS.code_executed += 1
        
        console.print()
        border = C["green"] if success else C["red"]
        console.print(Panel(
            output or "(no output)",
            title=f"[bold {border}]{'▶ Output' if success else '✗ Failed'}[/]",
            border_style=border, padding=(0, 1),
            expand=False
        ))
        
        if "cancelled" in output.lower():
            break
            
        last_success = success
        if success:
            # Smart warning if code successfully executed but didn't write to any files
            contains_file_write = any(term in code for term in ["open(", "write(", "writelines(", "Remove-Item", "rm ", "del ", "mkdir", "w+", "a+", "w", "wb"])
            warning_footer = ""
            if not contains_file_write and any(keyword in task["title"].lower() or keyword in task["description"].lower() for keyword in ["create", "write", "save", "edit", "update", "modify", "add", "file"]):
                warning_footer = (
                    "\n\n⚠️ NOTE: This code executed successfully, but it did not appear to write or modify any files on disk. "
                    "If this subtask requires creating or updating a file, you MUST write a Python script that explicitly writes "
                    "the content to disk (e.g., using `with open('filename', 'w') as f: f.write(...)`). Please do not output raw file contents; "
                    "output code that writes it!"
                )
            
            # If the code block ran successfully and the agent already declared SUBTASK_COMPLETE
            # in this turn, we can immediately declare victory and transition!
            if "SUBTASK_COMPLETE" in resp:
                break
                
            sub_conv.add("user", (
                f"[EXECUTION SUCCESSFUL]\n"
                f"Output:\n{output}{warning_footer}\n\n"
                f"If this fully resolves Subtask {task_id}, output 'SUBTASK_COMPLETE' to advance. "
                f"Otherwise, provide the next step or validation."
            ))
            summary_notes.append(f"Ran {lang} block successfully")
        else:
            STATS.corrections += 1
            sub_conv.add("user", (
                f"[EXECUTION FAILED]\n"
                f"Error:\n{output}\n\n"
                f"Please diagnose the failure, correct the code block, and run again."
            ))
            summary_notes.append("Failed execution")
            
    if last_success:
        task["status"] = "completed"
        summary = f"✓ Subtask {task_id}: {task['title']} - Completed successfully. ({len(summary_notes)} code runs)"
        return True, summary
    else:
        task["status"] = "failed"
        summary = f"✗ Subtask {task_id}: {task['title']} - Failed to complete."
        return False, summary

def run_divide_and_conquer_orchestrator(conv: Conversation, user_input: str, subtasks: list[dict], last_response_ref: list) -> str:
    """
    Drives sequential subtask completion, managing state, retries, and providing the user
    with an elite visual dashboard at every step.
    """
    total_tasks = len(subtasks)
    console.print(Panel(
        f"[bold {C['green']}]⚡ DIVIDE & CONQUER ENGAGED ⚡[/]\n\n"
        f"Decomposed request into [bold]{total_tasks}[/] sequential subproblems.\n"
        f"Athena will now solve each task autonomously.",
        border_style=C["green"],
        padding=(0, 2)
    ))
    
    task_summaries = []
    idx = 0
    while idx < total_tasks:
        task = subtasks[idx]
        render_task_board(user_input, subtasks, current_id=task["id"])
        
        success, summary = run_subtask(task, subtasks, user_input, total_tasks)
        task_summaries.append(summary)
        
        if success:
            console.print(f"\n  [bold {C['green']}]✓ Completed: {task['title']}[/]\n")
            idx += 1
        else:
            console.print(f"\n  [bold {C['red']}]✗ Failed: {task['title']}[/]\n")
            console.print(Panel(
                f"[bold {C['red']}]⚠ SUBTASK EXECUTION UNRESOLVED[/]\n\n"
                f"Subtask {task['id']}: [bold]{task['title']}[/]\n"
                f"Description: {task['description']}\n\n"
                f"How would you like to proceed?\n"
                f"[{C['green']}]r[/] = Retry this subtask\n"
                f"[{C['yellow']}]s[/] = Skip this subtask (mark complete anyway)\n"
                f"[{C['red']}]a[/] = Abort entire plan",
                border_style=C["red"],
                padding=(0, 2)
            ))
            try:
                action = input("  › ").strip().lower()
            except (KeyboardInterrupt, EOFError):
                action = "a"
                
            if action in ("r", "retry"):
                task["status"] = "pending"
                task_summaries.pop()
                continue
            elif action in ("s", "skip"):
                task["status"] = "completed"
                task_summaries[-1] = f"✓ Subtask {task['id']}: {task['title']} (Skipped/Forced complete)"
                idx += 1
            else:
                console.print(f"\n  [{C['red']}]Plan aborted by user.[/]\n")
                break
                
    # Mark any remaining tasks as failed if aborted
    for remaining in subtasks[idx:]:
        remaining["status"] = "failed"
        
    render_task_board(user_input, subtasks, current_id=-1)
    
    # Final Review & Summary Generation
    console.print(Rule(f"[bold {C['primary']}] Final Review & Synthesis [/]", style=C["primary"]))
    
    final_summary_prompt = (
        f"=== DIVIDE & CONQUER PLAN COMPLETED ===\n"
        f"Overall Goal: {user_input}\n\n"
        f"Subtask Summaries:\n" + "\n".join(task_summaries) + "\n\n"
        f"Provide a comprehensive, high-level summary of the accomplishments, "
        f"files created or modified, and confirm the entire workspace is in a perfect state. "
        f"Do NOT generate or include any code blocks or commands in this response. "
        f"Just summarize the accomplishments in clean, professional, and visually spectacular formatting."
    )
    
    msgs = [
        {"role": "system", "content": CFG["system_prompt"]},
        {"role": "user", "content": final_summary_prompt}
    ]
    
    final_response = stream_response(msgs)
    if final_response:
        conv.add("assistant", final_response)
        last_response_ref[0] = final_response
        conv.save()
        return final_response
    return "All tasks executed. Plan complete."

def run_agent_loop(conv: Conversation, user_input: str, last_response_ref: list) -> str:
    """
    Core agentic loop:
    1. Checks clarification needed
    2. Decomposes request via Divide & Conquer if complex coding/development is required
    3. Streams response & executes code block autonomously
    4. Feeds execution output back into loop and self-corrects
    """
    # Step 1: Clarification check for complex/ambiguous requests
    if len(user_input) > 30:
        clarify = check_clarification_needed(user_input)
        if clarify.get("needs_clarification") and clarify.get("confidence", 1.0) < 0.7:
            ambiguities = clarify.get("ambiguities", [])
            assumed = clarify.get("assumed_interpretation", "")
            console.print(Panel(
                f"[bold {C['yellow']}]⚠ Ambiguity Detected[/]\n\n"
                + "\n".join(f"  [{C['white']}]• {a}[/]" for a in ambiguities)
                + (f"\n\n[{C['dim']}]Assumed: {assumed}[/]" if assumed else "")
                + f"\n\n[{C['dim']}]Press Enter to proceed with assumption, or clarify:[/]",
                border_style=C["yellow"], padding=(0, 2),
            ))
            STATS.clarifications += 1
            try:
                clarification = input("  › ").strip()
                if clarification:
                    user_input = clarification
                    conv.messages[-1]["content"] = clarification
            except (KeyboardInterrupt, EOFError):
                pass

    # Step 2: Divide & Conquer is now opt-in only.
    # Broad requests like "make a portfolio website" should be handled by a
    # concrete workflow or a single grounded pass, not an LLM-generated task maze.
    use_dc = False
    subtasks = []
    
    # Trivial / Read-only tasks should NEVER trigger Divide & Conquer
    is_trivial = any(term in user_input.lower() for term in [
        "show", "list", "ls", "dir", "read", "view", "cat", "display", "status", "log", 
        "diff", "search", "find", "grep", "what is", "why is", "how do", "explain", "who is", "help"
    ])
    
    is_complex = not is_trivial and (any(keyword in user_input.lower() for keyword in [
        "build", "create", "make", "fix", "implement", "write", "develop", "setup",
        "add", "optimize", "refactor", "integrate", "debug", "change", "modify"
    ]) or len(user_input.split()) > 10)
    
    wants_dc = any(phrase in user_input.lower() for phrase in [
        "divide and conquer", "decompose", "break into subtasks",
        "multi-agent", "subtask tracker", "autonomous plan",
    ])

    if wants_dc and CFG.get("plan_before_act", True) and is_complex:
        with console.status(
            f"[{C['secondary']}]Athena Planning: Decomposing request via Divide & Conquer…[/]",
            spinner="dots", spinner_style=C["primary"]
        ):
            subtasks = generate_divide_and_conquer_plan(user_input)
            
        if len(subtasks) >= 2:
            use_dc = confirm_dc_plan(user_input, subtasks)
            
    if use_dc:
        return run_divide_and_conquer_orchestrator(conv, user_input, subtasks, last_response_ref)

    # Standard / simple single-pass loop fallback
    console.print(f"  [{C['dim']}]Using grounded single-pass mode…[/]")
    last_response = ""
    max_turns = min(CFG.get("max_agent_turns", 8), 3)

    for turn in range(max_turns):
        msgs = conv.get_messages_for_api()
        resp = stream_response(msgs)

        if not resp:
            break

        conv.add("assistant", resp)
        last_response = resp
        last_response_ref[0] = resp
        STATS.total_words += len(resp.split())
        conv.save()

        # Detect code blocks
        blocks = extract_code_blocks(resp)
        if not blocks:
            break  # No code to run — done

        # Scan in chronological order to execute steps in order
        executable_block = None
        for l, c in blocks:
            c_clean = clean_shell_code(c)
            if not c_clean:
                continue
            runners = _build_runners(l, c_clean)
            if runners:
                executable_block = (l, c)
                break

        if not executable_block:
            break  # No executable code to run — done

        lang, code = executable_block

        # Trivial Print Guard: If the code is just a simple literal print/echo and turn > 0,
        # it is a verification placeholder from the model. Break the loop gracefully.
        code_lines = [line.strip() for line in code.split("\n") if line.strip() and not line.strip().startswith("#")]
        is_trivial_print = len(code_lines) > 0 and all(
            (line.startswith("print(") and line.endswith(")") and not any(kw in line for kw in ["open(", "os.", "sys.", "Path", "listdir", "read(", "subprocess", "glob"])) or 
            line.startswith("echo ") or 
            line.strip() in ["pass", "True", "False", "None"]
            for line in code_lines
        )
        if is_trivial_print and turn > 0:
            break

        # Run it
        # ALWAYS ask for permission before executing any command
        output, success = run_code(lang, code, silent_confirm=False)
        STATS.code_executed += 1

        console.print()
        border = C["green"] if success else C["red"]
        console.print(Panel(
            output or "(no output)",
            title=f"[bold {border}]{'▶ Output' if success else '✗ Failed'}[/]",
            border_style=border, padding=(0, 1),
        ))

        # Cancelled / user stopped
        if "cancelled" in output.lower():
            break

        # Feed result back into loop for self-correction
        if success:
            feedback = (
                f"[EXECUTION RESULT]\nCode ran successfully.\nOutput:\n{output}\n\n"
                f"Verify the task is fully complete. If done, confirm briefly. "
                f"If more steps are needed, proceed with the next step."
            )
        else:
            STATS.corrections += 1
            if STATS.corrections >= 3:
                console.print(f"\n  [bold {C['yellow']}]⚠ Self-Correction limit reached (3 failed attempts). Pausing loop to prevent infinite retries.[/]")
                break
            feedback = (
                f"[EXECUTION FAILED]\nError:\n{output}\n\n"
                f"Diagnose the root cause. Output a corrected version. "
                f"If the fix requires a different approach, explain briefly then provide the fix."
            )
        conv.add("user", feedback)
        continue

    else:
        console.print(f"\n[{C['yellow']}]⚠ Agent loop limit reached ({max_turns} turns). Pausing.[/]")

    return last_response


