---
name: kanban
description: 任务看板。Use when 多 agent 协作派活与互见进展、任务有依赖顺序、要看全局状态、周期任务防重复建卡时。
---

# Kanban 任务看板

看板 = 当前工作区的 `.yomi/kanban/` 目录：一张卡一个 md，目录即状态列，`kb` 的 mv 即流转。无数据库、无守护进程。`kb` = `python3 <skill目录>/scripts/kb.py`（仅标准库；`KB_DIR` 换看板位置，`KB_OWNER` 设默认认领人）。

## 列与状态机（5 列，唯一路径）

```
.yomi/kanban/
  todo/     待领（依赖未满足的卡在 board 里标 ⏸）
  doing/    已认领
  review/   待验收
  blocked/  卡壳带原因；满 2 次=熔断
  done/YYYY-MM/   终态
```

`todo → doing → review → done`；`doing → blocked → todo`；`review → doing`（打回）。done 是终态，重做新建卡。review 无直达 done 的捷径：solo 小卡 `pass`+`done` 连敲两条。

## 命令

```bash
kb                       # 看板全景（默认命令）
kb new "标题" [-m 描述] [--after 父id[,父id...]] [--key 幂等键]
kb claim ID [--as sess_xxx]   # todo→doing，有依赖闸
kb pass ID               # doing→review，有 Result 闸
kb done ID               # review→done，提示解锁卡
kb reject ID "原因"       # review→doing
kb block ID "原因"        # doing→blocked
kb unblock ID            # blocked→todo
kb log ID "一句话"        # 追加 ## Log
kb show ID / kb ls [列]   # 看卡 / TSV 清单
```

卡文件名 `<id>-<slug>.md`，id 取第一个 `-` 之前。卡顶部自带规则块（含 kb 完整命令与看板位置）——执行者没装本 skill、不在看板目录也能照做，**卡内规则块是执行者的单一事实源**。正文随时可编辑，流转只走 `kb`。

## 三种角色

**协调者**：拆工作包 → `kb new` 建卡（正文写全上下文+验收标准，执行者没有你的上下文）→ 派活给协作 agent 时给卡 id（卡里有 kb 完整命令）。依赖用 `--after`（多父=全部 done 才解锁；要"等任一"就拆卡）；周期任务用 `--key "$(date +%F)-xxx"` 防重复建卡。看全局跑 `kb board`。完成判据：每张活卡都有 owner 或明确的 after 链。

**执行者**：`kb claim ID --as <自己 session id>` 先认领 → 进展随手 `kb log` → 填 `## Result` 三行（结果/产物/遗留）→ `kb pass`。卡壳即 `kb block ID "原因"`；被 reject 的原因在 ## Log，改完重新 `pass`。完成判据：卡状态与真实进度一致，以文件为准。

**验收者**（人或 verifier 模板）：`kb board` 看 REVIEW 列 → `kb show` 审 Result 与产物 → 过 `kb done`，不过 `kb reject ID "差什么"`。完成判据：REVIEW 列清零。

## 黑板：多 agent 互见进展

进展与对 peers 有用的发现都写 `kb log`；`kb board` 里 doing/review/blocked 每卡下面直接显示最新一条 log。开工前、卡住时先 `kb board` 看 peers。

## 边界

- 一个工作区一块板（5 列封顶）；要隔离用 `KB_DIR`。
- 自动派发：用 yomi cron 定时跑「`kb board` + 派活」会话，skill 内不设 dispatcher。
- 2026-08-29 起取代 task-tickets/blackboard：新任务一律进本看板，历史 `.yomi/tickets/archive/` 仅备查。
