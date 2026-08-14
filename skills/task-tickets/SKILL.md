---
name: task-tickets
description: 工单（tickets）派活与跨 session 待办：一个任务一个 md 文件，落在工作区 .yomi/tickets/。Use when 拆解任务派发给 subagent 并发执行、回报或更新任务进度、验收聚合子 agent 产出时。
---

# Tickets

tickets 是工作区里的 `.yomi/tickets/` 目录，一个任务一个工单文件，跨 session 持久。**核心用法是派活：工单文件就是派工单，状态在文件里流转，别人发现你工作的唯一途径就是工单状态。**

## 建单：走脚本

建单用 `scripts/ticket.sh`（在本 skill 目录下），不手写 frontmatter——脚本保证 id/slug/时间戳/格式合规：

```bash
<baseDir>/scripts/ticket.sh new --dir <工作区> --title "任务名" --body "描述 + 验收标准"   # 输出文件路径
```

`--body` 缺省且 stdin 非 tty 时从 stdin 读。

## 状态流转：直接改文件

状态机：`pending → claimed → done | blocked`；`blocked → claimed`（复工）；`claimed → pending`（重置）；`done` 是终态不流转（要重做请新建工单）。

- **签收**：`status:` 改 `claimed`；frontmatter 加（或改）一行 `owner_session_id: "sess_..."`——填自己的 session id（在系统提示的 Environment 段）。
- **完结**：`status:` 改 `done`；正文末尾补一节标题恰为 `## Result` 的结果段（结果摘要 + 关键产物路径）。
- **卡壳**：`status:` 改 `blocked`；正文末尾追加一行 `> [YYYY-MM-DD] 卡在哪、需要什么`。
- **重置回 pending**：`status:` 改 `pending`；删掉 `owner_session_id:` 行；可追加备注行说明原因。

改 frontmatter 时注意：键名不动；**别加 `updated_at`**（显示时间由文件 mtime 派生）。

## 文件格式

`.yomi/tickets/<id>-<slug>.md`：

```markdown
---
title: 一句话任务名
status: pending | claimed | done | blocked
owner_session_id: sess_...    # 签收时填自己的 session id
created_at: 2026-08-09T10:00:00+08:00
---

> **工单规则**（编辑本文件前必读；没装 task-tickets skill 也按此来）：
> - 状态机：pending → claimed → done | blocked；blocked → claimed（复工）；claimed → pending（重置）；done 终态不流转（重做请新建工单）。
> - 签收：status 改 claimed；frontmatter 加 `owner_session_id: "sess_..."`（自己的 session id）。
> - 完结：status 改 done；文末补 `## Result` 节（结果摘要 + 产物路径）。
> - 卡壳：status 改 blocked；文末追加 `> [YYYY-MM-DD] 卡点与需要`。
> - frontmatter 键名不动；别加 updated_at（显示时间由文件 mtime 派生）。

任务描述 + 可检查的验收标准。

## Result
（完成时写：结果摘要 + 关键产物路径）
```

顶部规则块由建单脚本自动注入——**工单自解释，执行者无需安装本 skill**。id 是 7 位随机字母数字串（如 `t3m9q2x`），脚本建单自动铸造——kernel 投影取文件名第一个 `-` 前为 id。

## 派活（协调者）

1. 拆工作包，每包用脚本 `new` 建单。派工单正文要上下文写全——执行者没有你的上下文，工单就是它知道的一切。
2. spawn 子 agent 时在 prompt 里**指明它的工单路径**（"你的单是 `.yomi/tickets/t3m9q2x-xxx.md`"）；一批任务可以并发派多个。工单顶部自带编辑规则，执行者没装本 skill 也能照做。
3. 完成标准：每个工作包都有工单且已随 spawn 指派，`grep -l "status: pending" .yomi/tickets/*.md` 能列出全部未签收工单。

## 干活（执行者）

1. 被派到任务后**先签收再动手**（按「状态流转」节置 claimed + 填 owner）——签收让工单与现实一致。
2. 干活。完成置 done 写 Result；卡壳置 blocked 写清卡点。过程性的进展/发现写到 blackboard（多 agent 协作时，见 blackboard skill）；工单记状态与结果，不必搬运过程。
3. 完成标准：工单状态与真实进度一致。口头说"做完了"不算数，文件里 done 才算。

## 聚合验收（协调者）

1. `grep "^status:" .yomi/tickets/*.md` 一把看全局；子 agent 会自己更新文件，汇总靠读文件，不逐个发消息追问。
2. 全部 done 后统一验收（可派 `verifier` 模板做独立验收），通过的文件 `mv` 进 `.yomi/tickets/archive/`。
3. 完成标准：主目录只剩未完结工单。
