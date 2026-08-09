---
name: task-board
description: 共享任务板（board）协调多 agent 工作：一个任务一个 md 文件，落在工作区的 .yomi/board/。Use when 拆解任务派发给 subagent 并发执行、认领或继续 board 上的任务、回报任务进度/结果，或需要跨 session 跟踪谁在做什么时候。
---

# Task Board

board 是工作区里的 `.yomi/board/` 目录，一个任务一个文件，是本工作区所有 agent 共享的唯一事实源。开工前先看板，干活中勤更新——别人发现你工作的唯一途径就是板上的文件状态。

## 文件格式

`.yomi/board/<id>-<slug>.md`。id = 项目前缀 + 5 位字母数字（如 `yb-t3m9q`），每个任务现造一个，不与现有文件重复。

```markdown
---
title: 一句话任务名
status: pending | claimed | done | blocked
owner_session_id: sess_...    # 认领时填自己的 session id
created_at: 2026-08-09T10:00:00+08:00
---

任务描述 + 可检查的验收标准。

## Result
（完成时写：结果摘要 + 关键产物路径）
```

## 创建任务（协调者）

1. 把工作拆成可独立完成的工作包，每包一个文件：标题一行、验收标准可检查、正文写清上下文（board 文件就是派工单，认领者没有你的上下文）。
2. 全部置 `status: pending`，不填 owner。
3. 完成标准：每个工作包都有独立 board 文件，且 `grep -l "status: pending" .yomi/board/*.md` 能列出全部新任务。

## 认领任务

1. `grep -l "status: pending" .yomi/board/*.md`，逐个读正文选一个能做的（`archive/` 子目录是归档，不在其列）。
2. **先改文件再动手**：把 `status` 改为 `claimed`、`owner_session_id` 填自己的 session id——这一步编辑就是认领本身。
3. 完成标准：任务文件里 owner 是你，然后才开始干活。

## 更新状态

- 完成：`status: done` 并补 `## Result`（结果摘要 + 产物路径）。
- 卡壳：`status: blocked`，正文写清卡在哪、需要什么。
- 完成标准：文件状态与真实进度一致。口头说"做完了"不算数，文件里 done 才算。

## 聚合进度（协调者）

1. `grep "^status:" .yomi/board/*.md` 一把看全局；agent 完成了会自己更新文件，汇总靠读文件，不向子 agent 逐个发消息追问。
2. 全部 done 后统一验收，然后把文件挪进 `.yomi/board/archive/`（主目录只留活任务）。
3. 完成标准：主目录里只剩 pending/claimed/blocked 的任务。
