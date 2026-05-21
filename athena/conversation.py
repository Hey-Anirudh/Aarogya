"""Conversation manager — message history, save/load, search."""
import json
from datetime import datetime
from pathlib import Path
from athena.config import CFG, CONV_DIR
from athena.memory import MEMORY
from athena.ui import get_env_context


class Conversation:
    def __init__(self):
        self.messages: list[dict] = []
        self.title: str = "New Conversation"
        self.created_at: str = datetime.now().isoformat()
        self.id: str = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.tags: list[str] = []

    def add(self, role: str, content: str):
        self.messages.append({"role": role, "content": content})
        max_msgs = CFG["context_window"] * 2
        if len(self.messages) > max_msgs:
            # Keep system context + trim oldest non-system messages
            self.messages = self.messages[-max_msgs:]
        if len(self.messages) == 1 and role == "user":
            self.title = content[:60] + ("…" if len(content) > 60 else "")

    def get_messages_for_api(self) -> list[dict]:
        sys_prompt = CFG["system_prompt"]
        if CFG.get("inject_cwd", True):
            sys_prompt += f"\n\n[Environment]\n{get_env_context()}"
        if MEMORY["facts"]:
            facts = "\n".join(f"• {f}" for f in MEMORY["facts"][:15])
            sys_prompt += f"\n\n[User Memory]\n{facts}"
        if MEMORY.get("learned_corrections"):
            corrections = "\n".join(f"• {c}" for c in MEMORY["learned_corrections"][-5:])
            sys_prompt += f"\n\n[Learned from past mistakes]\n{corrections}"
        return [{"role": "system", "content": sys_prompt}, *self.messages]

    def save(self):
        if not CFG["auto_save"]:
            return
        path = CONV_DIR / f"{self.id}.json"
        path.write_text(json.dumps({
            "id": self.id, "title": self.title,
            "created_at": self.created_at,
            "messages": self.messages,
            "tags": self.tags,
        }, indent=2))

    @staticmethod
    def list_saved() -> list[dict]:
        convs = []
        for p in sorted(CONV_DIR.glob("*.json"), reverse=True)[:25]:
            try:
                data = json.loads(p.read_text())
                convs.append(data)
            except Exception:
                pass
        return convs

    @staticmethod
    def load(conv_id: str) -> "Conversation":
        path = CONV_DIR / f"{conv_id}.json"
        if not path.exists():
            raise FileNotFoundError(f"Conversation {conv_id} not found")
        data = json.loads(path.read_text())
        c = Conversation()
        c.id = data["id"]; c.title = data["title"]
        c.created_at = data["created_at"]
        c.messages = data["messages"]
        c.tags = data.get("tags", [])
        return c

    def search(self, query: str) -> list[dict]:
        """Search messages for query string."""
        q = query.lower()
        return [m for m in self.messages if q in m["content"].lower()]


