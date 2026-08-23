---
name: blackboard
description: 多 agent 共享黑板：.yomi/boards/<feature>.md，一个 feature 一块，让同一 feature 下并行的 agent 互见 task/progress/findings。Use when 多 agent 协作需要 peer visibility、共享进展/发现、开工前想知道 peers 在干什么。派单/签收/验收走 task-tickets。
---

# Blackboard 黑板

blackboard = 当前目录的 `.yomi/boards/<feature>.md`,**一个 feature 一块 board**。一个目录可能同时有 n 个 feature 在跑,每个 feature 的 agent 团队各看各的 board。同一块 board 上的所有 agent 读同一个文件,一眼看到 peers 的 task、progress、findings——这是 task-tickets 没有的视角(ticket 里 worker 只看得到自己的那张)。

分工:派单/签收/状态机/验收走 task-tickets;blackboard 管 **peer visibility**(progress 与 findings),不是 task 的 system of record。

## 位置与命名

- `<feature>` = 开局者起的 feature slug(如 `auth-refactor`);谁开局谁建 board(通常是 leader),按模板创建。
- `ls .yomi/boards/` 列出本目录全部 in-flight 的 feature board。
- spawn 子 agent 时在 prompt 里给 **board 的绝对路径**,不靠对方用自己的 CWD 猜(子目录里会建错 board);同一 feature 的所有 agent 必须拿到同一路径。
- feature 收尾:leader 验收后删掉该 board,不让 board 越积越多。

## 模板

```markdown
# Board

## Agents

### <who>
- task: <ticket id + title>
- status: doing | done
- progress: ...(最新一条)
- updated_at: HH:MM
- notes: ...(对 peers 有用的 findings)
```

## 规则

1. **先 check-in 再开工** —— 领到活后在 Agents 下加自己的 `### <who>` section,写上 task(ticket id + 标题)和第一条 progress。who = 角色名 + 自己系统提示 Environment 段的 session id 前缀,如 `worker-auth sub_01KZ`(主 session 是 `sess_*`,subagent 是 `sub_*`;与 ticket 的 owner_session_id 同源)。
2. **只改自己的 section** —— progress 只留最新一条,顺手刷新 updated_at;对 peers 有用的 finding 写进自己的 notes 行。永不动别人的 section。
3. **收工标 done** —— status 改 `done`,result 摘要写进 progress 行;leader 验收后删 section(整块 board 的删除见「位置与命名」)。
4. **读 board** —— 开工前、卡住时读一遍自己 feature 的 board:peer 可能已解决了你的问题,或在改你要改的文件。
5. **并发** —— 同时写靠 edit 的精确匹配兜底:edit 失败 = 有人刚改过,re-read 再改。

完成判据:Agents 下的 section 与真实在跑的 agent 一一对应;每个 done section 带 result 摘要。
