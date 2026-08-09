---
name: task-tickets
description: 工单（tickets）派活与跨 session 待办：一个任务一个 md 文件，落在工作区 .yomi/tickets/。Use when 拆解任务派发给 subagent 并发执行、回报或更新任务进度、验收聚合子 agent 产出，或新 session 接手未完成工作时。
---

# Tickets

tickets 是工作区里的 `.yomi/tickets/` 目录，一个任务一个工单文件，跨 session 持久。**核心用法是派活：工单文件就是派工单，状态在文件里流转，别人发现你工作的唯一途径就是工单状态。**

## 生命周期操作：一律走脚本

建单和状态流转用 `scripts/ticket.sh`（在本 skill 目录下），不用手写 frontmatter——脚本保证 id/slug/时间戳/格式合规，并拒绝非法状态流转：

```bash
S=<baseDir>/scripts/ticket.sh

$S new --dir <工作区> --title "任务名" --body "描述 + 验收标准"   # 建单，输出文件路径
$S set <文件> claimed --by <你的 session id>                    # 签收
$S set <文件> done --result "结果摘要 + 产物路径"               # 完结
$S set <文件> blocked --note "卡在哪、需要什么"                 # 卡壳
$S set <文件> pending --note "原因"                             # 重置（清 owner）
```

## 文件格式

`.yomi/tickets/<id>-<slug>.md`：

```markdown
---
title: 一句话任务名
status: pending | claimed | done | blocked
owner_session_id: sess_...    # 签收时填自己的 session id
created_at: 2026-08-09T10:00:00+08:00
---

任务描述 + 可检查的验收标准。

## Result
（完成时写：结果摘要 + 关键产物路径）
```

手工编辑正文时注意：frontmatter 键名不动；**别加 `updated_at`**（显示时间由文件 mtime 派生）；id 是 7 位随机字母数字串（含字母+数字，如 `t3m9q2x`），脚本建单自动铸造。

## 派活（协调者）

1. 拆工作包，每包用脚本 `new` 建单。派工单正文要上下文写全——执行者没有你的上下文，工单就是它知道的一切。
2. spawn 子 agent 时在 prompt 里**指明它的工单路径**（"你的单是 `.yomi/tickets/t3m9q2x-xxx.md`"）；一批任务可以并发派多个。
3. 完成标准：每个工作包都有工单且已随 spawn 指派，`grep -l "status: pending" .yomi/tickets/*.md` 能列出全部未签收工单。

## 干活（执行者）

1. 被派到任务后**先签收再动手**（`set ... claimed --by <你的 session id>`，session id 在系统提示的 Environment 段）——签收让工单与现实一致。
2. 干活。完成 → `set ... done --result "..."`；卡壳 → `set ... blocked --note "..."`。
3. 完成标准：工单状态与真实进度一致。口头说"做完了"不算数，文件里 done 才算。

## 聚合验收（协调者）

1. `grep "^status:" .yomi/tickets/*.md` 一把看全局；子 agent 会自己更新文件，汇总靠读文件，不逐个发消息追问。
2. 全部 done 后统一验收（可派 `reviewer` 模板做独立验收），通过的文件 `mv` 进 `.yomi/tickets/archive/`。
3. 完成标准：主目录只剩未完结工单。

## 捡活（跨 session 接手）

- 新 session 开工前、或手上活干完时：`grep -l "status: pending" .yomi/tickets/*.md` 看待办。
- `claimed` 但文件 mtime 超过 30 分钟未更新的多半是僵尸（认领者已死）：`set ... pending --note "僵尸回收：认领者失联"`，然后自己签收接着干。
