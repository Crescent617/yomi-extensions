---
name: tickets
description: 工单（tickets）派活与跨 session 待办：一个任务一个 md 文件，落在工作区 .yomi/tickets/。Use when 拆解任务派发给 subagent 并发执行、回报或更新任务进度、验收聚合子 agent 产出，或新 session 接手未完成工作时。
---

# Tickets

tickets 是工作区里的 `.yomi/tickets/` 目录，一个任务一个工单文件，跨 session 持久。**核心用法是派活：工单文件就是派工单，状态在文件里流转，别人发现你工作的唯一途径就是工单状态。**

## 生命周期操作：一律走脚本

建单和状态流转用 `scripts/ticket.sh`（在本 skill 目录下），不用手写 frontmatter——脚本保证 id/slug/时间戳/格式合规，并拒绝非法状态流转：

```bash
S=<本 skill 目录>/scripts/ticket.sh

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

### 规范（与 kernel 投影解析对齐，违反会静默降级显示）

- **id**：2–4 个小写字母前缀（不含 `-`）+ `-` + 恰好 5 位小写字母数字，如 `yt-t3m9q`；现造，不与现有文件重复（用脚本建单则自动满足）。
- **slug**：小写单词以 `-` 连接（`fix-auth-timeout`）。
- **frontmatter**：
  - `title`：可省（缺省从 slug 推导）；写了就单行纯文本 ≤60 字符，供侧栏显示。
  - `status`：必填，四值枚举 `pending`/`claimed`/`done`/`blocked`。
  - `owner_session_id`：签收时必填（自己的 session id）；重置 pending 时清空。
  - `created_at`：必填，RFC3339 带时区。
  - **不写 `updated_at`**——由文件 mtime 自动派生，手写的会与真实更新时间矛盾。
- **正文**：任务描述 + 验收标准（逐条、可检查）；完成时追加标题恰为 `## Result` 的结果段（摘要 + 产物路径）。
- **状态机**：`pending → claimed → done|blocked`；`blocked → claimed`（复工）；`claimed → pending`（僵尸重置，正文注明原因）。脚本强制执行。
- **归档**：完结文件移入 `.yomi/tickets/archive/`（子目录不计入活跃板）。

## 派活（协调者）

1. 拆工作包，每包用脚本 `new` 建单。派工单正文要上下文写全——执行者没有你的上下文，工单就是它知道的一切。
2. spawn 子 agent 时在 prompt 里**指明它的工单路径**（"你的单是 `.yomi/tickets/yt-xxx.md`"）；一批任务可以并发派多个。
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
