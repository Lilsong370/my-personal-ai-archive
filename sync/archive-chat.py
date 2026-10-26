#!/usr/bin/env python3
"""
把 AI 对话记录归档进 journal/YYYY-MM/YYYY-MM-DD.md

四种用法：

  1. 直接给文本
     python sync/archive-chat.py --text "AI 的输出" --tag chatgpt --title "客诉话术"

  2. 从剪贴板（Windows）
     Get-Clipboard | python sync/archive-chat.py --tag claude --title "周报模板"

  3. 从文件
     python sync/archive-chat.py --file note.md --tag gemini

  4. 导入 ChatGPT / Claude 的完整导出
     python sync/archive-chat.py --export conversations.json

归档后可以顺手同步：
     python sync/archive-chat.py --text "..." --tag claude --sync
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
JOURNAL = ROOT / "journal"


def slugify(text: str, limit: int = 30) -> str:
    text = re.sub(r"[\\/:*?\"<>|\r\n\t]+", " ", text).strip()
    text = re.sub(r"\s+", " ", text)
    return text[:limit] or "未命名"


def day_file(when: dt.datetime) -> Path:
    d = JOURNAL / when.strftime("%Y-%m")
    d.mkdir(parents=True, exist_ok=True)
    return d / (when.strftime("%Y-%m-%d") + ".md")


def append_entry(body: str, tag: str, title: str, when: dt.datetime | None = None) -> Path:
    when = when or dt.datetime.now()
    body = body.strip()
    if not body:
        raise SystemExit("内容为空，没有可归档的东西")

    f = day_file(when)
    if not f.exists():
        f.write_text(f"# {when:%Y-%m-%d} · 对话记录\n", encoding="utf-8")

    head = f"## {when:%H:%M} · {tag}"
    if title:
        head += f" · {title}"
    with f.open("a", encoding="utf-8") as fh:
        fh.write(f"\n{head}\n\n{body}\n")
    return f


def _msg_text(content) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, dict):
        parts = content.get("parts")
        if isinstance(parts, list):
            out = []
            for p in parts:
                if isinstance(p, str):
                    out.append(p)
                elif isinstance(p, dict) and isinstance(p.get("text"), str):
                    out.append(p["text"])
            return "\n".join(x for x in out if x.strip())
        if isinstance(content.get("text"), str):
            return content["text"]
    return ""


def parse_chatgpt(conv: dict) -> tuple[str, dt.datetime, list[tuple[str, str]]]:
    title = conv.get("title") or "未命名对话"
    ts = conv.get("create_time")
    when = dt.datetime.fromtimestamp(ts) if isinstance(ts, (int, float)) else dt.datetime.now()

    rows = []
    mapping = conv.get("mapping") or {}
    for node in mapping.values():
        msg = (node or {}).get("message") or {}
        role = ((msg.get("author") or {}).get("role") or "").strip()
        if role not in {"user", "assistant"}:
            continue
        text = _msg_text(msg.get("content")).strip()
        if not text:
            continue
        t = msg.get("create_time")
        rows.append((t if isinstance(t, (int, float)) else 0, role, text))

    rows.sort(key=lambda r: r[0])
    convo = [(role, text) for _, role, text in rows]
    return title, when, convo


def parse_claude(conv: dict) -> tuple[str, dt.datetime, list[tuple[str, str]]]:
    title = conv.get("name") or "未命名对话"
    msgs = conv.get("chat_messages") or []
    rows = []
    for m in msgs:
        sender = (m.get("sender") or "").strip()
        role = "user" if sender == "human" else "assistant"
        text = (m.get("text") or "").strip()
        if text:
            created = m.get("created_at") or ""
            rows.append((str(created), role, text))
    when = dt.datetime.now()
    if rows and rows[0][0]:
        try:
            when = dt.datetime.fromisoformat(rows[0][0].replace("Z", "+00:00")).astimezone()
        except ValueError:
            pass
    return title, when, [(role, text) for _, role, text in rows]


def import_export(path: Path, max_chars: int, sync: bool, tag: str) -> int:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise SystemExit("导出文件格式不认识：需要一个对话数组")

    total = 0
    for conv in data:
        if not isinstance(conv, dict):
            continue
        if "mapping" in conv:
            title, when, convo = parse_chatgpt(conv)
        elif "chat_messages" in conv:
            title, when, convo = parse_claude(conv)
        else:
            continue
        if not convo:
            continue

        lines = []
        size = 0
        for role, text in convo:
            block = f"**{'我' if role == 'user' else 'AI'}**\n\n{text}\n"
            if size + len(block) > max_chars:
                lines.append("\n_（以下内容超出单条上限，已截断）_\n")
                break
            lines.append(block)
            size += len(block)

        append_entry("\n".join(lines), tag=tag, title=slugify(title), when=when)
        total += 1

    if sync and total:
        do_sync()
    return total


def do_sync():
    ps1 = ROOT / "sync" / "sync.ps1"
    subprocess.run(
        ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(ps1)],
        check=False,
    )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--text", help="要归档的正文")
    ap.add_argument("--file", help="从文件读取正文")
    ap.add_argument("--export", help="ChatGPT/Claude 导出 JSON")
    ap.add_argument("--tag", default="ai", help="来源标签，如 chatgpt / claude / gemini")
    ap.add_argument("--title", default="", help="这条记录的主题")
    ap.add_argument("--max-chars", type=int, default=20000, help="单条对话上限（导出模式）")
    ap.add_argument("--sync", action="store_true", help="归档后自动提交推送")
    args = ap.parse_args()

    if args.export:
        tag = args.tag if args.tag != "ai" else "export"
        n = import_export(Path(args.export), args.max_chars, args.sync, tag)
        print(f"已导入 {n} 个对话 → journal/")
        return 0

    if args.text:
        body = args.text
    elif args.file:
        body = Path(args.file).read_text(encoding="utf-8")
    elif not sys.stdin.isatty():
        body = sys.stdin.read()
    else:
        raise SystemExit("没有内容：用 --text / --file / 管道 传入，或 --export 导入")

    f = append_entry(body, tag=args.tag, title=args.title)
    print(f"已写入 {f.relative_to(ROOT)}")
    if args.sync:
        do_sync()
    return 0


if __name__ == "__main__":
    sys.exit(main())
