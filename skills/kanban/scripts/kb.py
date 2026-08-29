#!/usr/bin/env python3
"""kb — yomi 任务看板：一张卡一个 md，目录即状态，mv 即流转。

用法: kb [board] | new | claim | pass | done | reject | block | unblock | log | show | ls
环境: KB_DIR 看板目录（默认 .yomi/kanban）；KB_OWNER 默认认领人
"""
from __future__ import annotations

import argparse
import getpass
import os
import re
import secrets
import string
import sys
from datetime import datetime
from pathlib import Path

BOARD = Path(os.environ.get("KB_DIR", ".yomi/kanban"))
COLS = ("todo", "doing", "review", "blocked", "done")

CARD_TMPL = """---
id: {id}
title: {title}
owner:
after: {after}
key: {key}
created: {created}
---

> **看板规则**（改本文件前必读；没装 kanban skill 也按此来）：
> - kb = `{kb_cmd}`，下列"kb 命令"都指它（含看板位置，任意目录可跑）。
> - 状态机=目录：todo → doing → review → done；doing → blocked（卡壳）→ todo（unblock）；review → doing（打回）。done 是终态，重做请新建卡。
> - 流转一律用 kb 命令：claim 认领 / pass 送审 / done 通过 / reject 打回 / block 卡壳 / unblock 解锁。不手改目录，正文可随时编辑。
> - 送审前必须填好 ## Result 三行（结果/产物/遗留），否则 kb pass 会拒绝。
> - after 列出的父卡全部进 done 后本卡才能被认领；blocked 满 2 次=熔断，停止重试等人类处理。

{body}

## Result
**结果**：
**产物**：
**遗留**：

## Log
- [{time}] created
"""


def die(msg: str) -> None:
    print(f"kb: {msg}", file=sys.stderr)
    sys.exit(1)


def ensure_board() -> None:
    for c in COLS:
        (BOARD / c).mkdir(parents=True, exist_ok=True)


def find_card(cid: str) -> Path | None:
    for col in COLS[:4]:
        hits = sorted((BOARD / col).glob(f"{cid}-*.md"))
        if hits:
            return hits[0]
    hits = sorted(BOARD.glob(f"done/*/{cid}-*.md"))
    return hits[0] if hits else None


def must_card(cid: str) -> Path:
    p = find_card(cid)
    if p is None:
        die(f"卡 {cid} 不存在")
    return p


def col_of(path: Path) -> str:
    for c in COLS:
        if c in path.parts:
            return c
    return ""


def card_id(path: Path) -> str:
    return path.name.split("-")[0]


def fm(path: Path, key: str) -> str:
    # 注意：不能用 \s*（\s 吃换行，空值会吞掉下一行），只允许行内空白
    m = re.search(rf"^{re.escape(key)}:[^\S\n]*(.*)$", path.read_text(encoding="utf-8"), re.M)
    return m.group(1) if m else ""


def set_fm(path: Path, key: str, value: str) -> None:
    text = re.sub(rf"^{re.escape(key)}:.*$", f"{key}: {value}",
                  path.read_text(encoding="utf-8"), count=1, flags=re.M)
    path.write_text(text, encoding="utf-8")


def log_line(path: Path, msg: str) -> None:
    with path.open("a", encoding="utf-8") as f:
        f.write(f"- [{datetime.now():%H:%M}] {msg}\n")


def slugify(title: str) -> str:
    s = re.sub(r"[ /]+", "-", title)
    s = re.sub(r"[*?\[\]]", "", s)
    s = re.sub(r"-{2,}", "-", s).strip("-")
    s = s[:24].strip("-")
    return s or "card"


def mint_id() -> str:
    alphabet = string.ascii_lowercase + string.digits
    while True:
        cid = "".join(secrets.choice(alphabet) for _ in range(4))
        if find_card(cid) is None:
            return cid


def parents_of(after: str) -> list[str]:
    return [p.strip() for p in after.split(",") if p.strip()]


def unmet_parents(after: str) -> list[str]:
    """未进 done 的父卡 id 列表（不存在的带 ? 后缀）；全满足则空。"""
    out = []
    for p in parents_of(after):
        hit = find_card(p)
        if hit is None:
            out.append(p + "?")
        elif col_of(hit) != "done":
            out.append(p)
    return out


def move(path: Path, dst_dir: Path) -> Path:
    dst_dir.mkdir(parents=True, exist_ok=True)
    dst = dst_dir / path.name
    path.rename(dst)  # 同机 rename = 原子流转
    return dst


def cmd_board(_a) -> None:
    ensure_board()
    for col in COLS[:4]:
        cards = sorted((BOARD / col).glob("*.md"))
        print(f"{col.upper()} ({len(cards)})")
        for p in cards:
            mark = ""
            if col == "todo":
                unmet = unmet_parents(fm(p, "after"))
                if unmet:
                    mark = f"⏸ 等 {' '.join(unmet)}  "
            owner = fm(p, "owner")
            owner = f"  @{owner}" if owner else ""
            print(f"  {card_id(p)}  {mark}{fm(p, 'title')}{owner}")
            if col != "todo":  # 非 todo 卡带最新一条 log：一眼看到 peers 进展（吸收 blackboard 职责）
                lines = p.read_text(encoding="utf-8").rstrip("\n").splitlines()
                if lines and lines[-1].startswith("- ["):
                    print(f"      └ {lines[-1][2:]}")
    n = len(list(BOARD.glob("done/*/*.md")))
    print(f"DONE ({n})   — kb show <id> 看卡, kb ls done 列完成卡")


def cmd_new(a) -> None:
    ensure_board()
    if a.key:  # 幂等：同键返回已有卡
        for p in BOARD.rglob("*.md"):
            if fm(p, "key") == a.key:
                print(card_id(p))
                return
    for parent in parents_of(a.after):
        if find_card(parent) is None:
            die(f"父卡 {parent} 不存在")
    cid = mint_id()
    now = datetime.now().astimezone()
    body = a.body or "（补充任务描述与验收标准）"
    card = BOARD / "todo" / f"{cid}-{slugify(a.title)}.md"
    card.write_text(CARD_TMPL.format(
        id=cid, title=a.title, after=a.after, key=a.key,
        created=now.isoformat(timespec="seconds"),
        kb_cmd=f"KB_DIR={BOARD.resolve()} python3 {Path(__file__).resolve()}",
        body=body, time=now.strftime("%H:%M")), encoding="utf-8")
    print(cid)


def cmd_claim(a) -> None:
    p = must_card(a.id)
    if col_of(p) != "todo":
        die(f"只有 todo 列能认领（当前在 {col_of(p)}）")
    unmet = unmet_parents(fm(p, "after"))
    if unmet:
        die(f"依赖闸：父卡未完成 → {' '.join(unmet)}")
    dst = move(p, BOARD / "doing")
    set_fm(dst, "owner", a.owner)
    log_line(dst, f"claimed by {a.owner}")
    print(a.id)


def cmd_pass(a) -> None:
    p = must_card(a.id)
    if col_of(p) != "doing":
        die(f"只有 doing 列能送审（当前在 {col_of(p)}）")
    if not re.search(r"^\*\*结果\*\*：[^\S\n]*\S", p.read_text(encoding="utf-8"), re.M):
        die("## Result 未填：**结果** 行还是空的，先补三行再送审")
    dst = move(p, BOARD / "review")
    log_line(dst, "in review")
    print(a.id)


def cmd_done(a) -> None:
    p = must_card(a.id)
    if col_of(p) != "review":
        die(f"只有 review 列能归档（当前在 {col_of(p)}；打回用 kb reject）")
    dst = move(p, BOARD / "done" / datetime.now().strftime("%Y-%m"))
    log_line(dst, "done")
    print(a.id)
    for c in sorted((BOARD / "todo").glob("*.md")):  # 提示因此解锁的卡（只提示，不自动派发）
        after = fm(c, "after")
        if a.id in parents_of(after) and not unmet_parents(after):
            print(f"👉 依赖已满足，可认领: {card_id(c)}  {fm(c, 'title')}")


def cmd_reject(a) -> None:
    p = must_card(a.id)
    if col_of(p) != "review":
        die(f"只有 review 列能打回（当前在 {col_of(p)}）")
    dst = move(p, BOARD / "doing")
    log_line(dst, f"rejected: {a.reason}")
    print(a.id)


def cmd_block(a) -> None:
    p = must_card(a.id)
    if col_of(p) != "doing":
        die(f"只有 doing 列能卡壳（当前在 {col_of(p)}）")
    dst = move(p, BOARD / "blocked")
    log_line(dst, f"blocked: {a.reason}")
    n = len(re.findall(r"^- \[.*\] blocked:", dst.read_text(encoding="utf-8"), re.M))
    print(a.id)
    if n >= 2:
        print(f"⚠️ 熔断：卡 {a.id} 已 {n} 次 blocked，停止重试，等人类处理", file=sys.stderr)


def cmd_unblock(a) -> None:
    p = must_card(a.id)
    if col_of(p) != "blocked":
        die(f"卡 {a.id} 不在 blocked 列")
    dst = move(p, BOARD / "todo")
    log_line(dst, "unblocked")
    print(a.id)


def cmd_log(a) -> None:
    p = must_card(a.id)
    log_line(p, a.msg)
    print(a.id)


def cmd_show(a) -> None:
    print(must_card(a.id).read_text(encoding="utf-8"), end="")


def cmd_ls(a) -> None:
    ensure_board()
    for col in ([a.col] if a.col else COLS):
        files = sorted(BOARD.glob("done/*/*.md")) if col == "done" \
            else sorted((BOARD / col).glob("*.md"))
        for p in files:
            print(f"{card_id(p)}\t{col}\t{fm(p, 'title')}")


def build_parser() -> argparse.ArgumentParser:
    ap = argparse.ArgumentParser(prog="kb", description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("board", help="看板全景（默认命令）")
    p = sub.add_parser("new", help="建卡")
    p.add_argument("title")
    p.add_argument("-m", "--body", default="")
    p.add_argument("--after", default="", help="父卡 id，逗号分隔多个；全部 done 才解锁")
    p.add_argument("--key", default="", help="幂等键：同键重复建卡返回已有卡")
    p = sub.add_parser("claim", help="认领 todo → doing")
    p.add_argument("id")
    p.add_argument("--as", dest="owner",
                   default=os.environ.get("KB_OWNER") or getpass.getuser())
    for name, helptext in [("pass", "送审 doing → review"), ("done", "通过 review → done"),
                           ("unblock", "解锁 blocked → todo"), ("show", "看卡全文")]:
        p = sub.add_parser(name, help=helptext)
        p.add_argument("id")
    for name, helptext in [("reject", "打回 review → doing"), ("block", "卡壳 doing → blocked")]:
        p = sub.add_parser(name, help=helptext)
        p.add_argument("id")
        p.add_argument("reason")
    p = sub.add_parser("log", help="追加进展到 ## Log")
    p.add_argument("id")
    p.add_argument("msg")
    p = sub.add_parser("ls", help="机器可读清单（TSV）")
    p.add_argument("col", nargs="?", default="")
    return ap


DISPATCH = {"board": cmd_board, "new": cmd_new, "claim": cmd_claim, "pass": cmd_pass,
            "done": cmd_done, "reject": cmd_reject, "block": cmd_block,
            "unblock": cmd_unblock, "log": cmd_log, "show": cmd_show, "ls": cmd_ls}


def main(argv: list[str]) -> None:
    if not argv:  # kb = kb board
        cmd_board(None)
        return
    args = build_parser().parse_args(argv)
    DISPATCH[args.cmd](args)


if __name__ == "__main__":
    main(sys.argv[1:])
