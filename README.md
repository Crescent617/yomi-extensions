# yomi-extensions

[yomi](https://github.com/Crescent617/yomi) harness 的官方扩展资产库——skills、agent templates，以及未来的更多扩展形态。设计文档见主仓 [`docs/archive/agent-harness.md`](https://github.com/Crescent617/yomi/blob/main/docs/archive/agent-harness.md)。

## 内容

skills 住 [`skills/`](skills/) 子目录，其他资产类型（如模板）各有顶层目录：

| 类型 | 资产 | 说明 |
|---|---|---|
| skill | [`skills/kanban/`](skills/kanban/SKILL.md) | 任务看板：`.yomi/kanban/` 目录即列，一卡一 md、mv 即流转；依赖闸（多父）、review 闸、cron 幂等键、blocked 熔断；卡的 ## Log 承担黑板职责（2026-08-29 起取代 task-tickets 与 blackboard） |
| skill | [`skills/memory-system-setup/`](skills/memory-system-setup/SKILL.md) | 一次性 bootstrap agent 记忆系统：AGENTS.md 记忆块、memory/ 目录（NOW.md 在途工作层 + diary + recall 检索）、dream + janitor 自进化 cron；装完即弃 |
| skill | [`skills/grill-me/`](skills/grill-me/SKILL.md) | 就计划/设计对用户穷追猛打式提问，直到决策树每个分支都收敛、达成共识 |
| skill | [`skills/handoff/`](skills/handoff/SKILL.md) | 任务交接文档方法论：何时写、结构怎么搭、不变量与易变信息分层 |
| skill | [`skills/coding-guideline/`](skills/coding-guideline/SKILL.md) | 写/review 代码的行为准则，减少常见编码错误 |
| skill | [`skills/writing-great-skills/`](skills/writing-great-skills/SKILL.md) | 写/改 skill 的规范：密度、结构、触发词、自由度、验证回路 |
| skill | [`skills/planning-with-files/`](skills/planning-with-files/SKILL.md) | 用持久化 markdown（plan/findings/progress）做复杂任务规划与进度追踪，防目标漂移 |
| skill | [`skills/tmux/`](skills/tmux/SKILL.md) | 远控 tmux session 驱动交互式 CLI：送键、抓屏、读输出 |
| skill | [`skills/fetch/`](skills/fetch/SKILL.md) | URL 抓取与正文提取：curl 落盘缓存（1h + stale-if-error）+ pandoc 提取 gfm（硬依赖），PDF/图片分发 |

janitor 不再单独规划——它作为 memory-system-setup 的两个常驻 cron 之一（完整 prompt）收录在该 skill 中。模板机制（`agent` 工具 `template` 参数、ROLE.md 约定）说明在 yomi 内核的工具 desc 与设计文档中，不再需要单独 skill。官方内置模板 planner/verifier/explorer/reviewer 预置在 yomi 内核（`crates/kernel/src/agent_tmpl/`），不在此仓。

## 安装

skills 用生态通用 CLI（默认识别 `skills/` 子目录，symlink 进 `~/.agents/skills/`，yomi 原生可读）：

```bash
npx skills add Crescent617/yomi-extensions --list    # 预览
npx skills add Crescent617/yomi-extensions -g        # 全局安装全部
npx skills add Crescent617/yomi-extensions -g --skill kanban   # 只装单个
```

或手动：

```bash
git clone https://github.com/Crescent617/yomi-extensions ~/repos/yomi-extensions
ln -s ~/repos/yomi-extensions/skills/kanban ~/.agents/skills/kanban
```

templates 不属于 skills 生态：官方模板内核预置、无需安装；本仓的实验性/社区模板手动 symlink 到 `~/.yomi/agents/`。

yomi 读 `~/.agents/skills/` 与项目内 `.agents/skills/`（项目覆盖全局），symlink 原生支持。
