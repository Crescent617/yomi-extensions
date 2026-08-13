# yomi-extensions

[yomi](https://github.com/Crescent617/yomi) harness 的官方扩展资产库——skills、agent templates，以及未来的更多扩展形态。设计文档见主仓 [`docs/design/agent-harness.md`](https://github.com/Crescent617/yomi/blob/main/docs/design/agent-harness.md)。

## 内容

skills 住 [`skills/`](skills/) 子目录，其他资产类型（如模板）各有顶层目录：

| 类型 | 资产 | 说明 |
|---|---|---|
| skill | [`skills/task-tickets/`](skills/task-tickets/SKILL.md) | 工单约定：`.yomi/tickets/` 目录、派单/签收/状态机、聚合验收、僵尸回收 |
| skill | [`skills/memory-system-setup/`](skills/memory-system-setup/SKILL.md) | 一次性 bootstrap agent 记忆系统：AGENTS.md 记忆块、memory/ 目录（NOW.md 在途工作层 + diary + recall 检索）、dream + janitor 自进化 cron；装完即弃 |

janitor 不再单独规划——它作为 memory-system-setup 的两个常驻 cron 之一（完整 prompt）收录在该 skill 中。模板机制（`agent` 工具 `template` 参数、ROLE.md 约定）说明在 yomi 内核的工具 desc 与设计文档中，不再需要单独 skill。官方内置模板 planner/verifier/explorer/reviewer 预置在 yomi 内核（`crates/kernel/src/agent_tmpl/`），不在此仓。

## 安装

skills 用生态通用 CLI（默认识别 `skills/` 子目录，symlink 进 `~/.agents/skills/`，yomi 原生可读）：

```bash
npx skills add Crescent617/yomi-extensions --list    # 预览
npx skills add Crescent617/yomi-extensions -g        # 全局安装全部
npx skills add Crescent617/yomi-extensions -g --skill task-tickets   # 只装单个
```

或手动：

```bash
git clone https://github.com/Crescent617/yomi-extensions ~/repos/yomi-extensions
ln -s ~/repos/yomi-extensions/skills/task-tickets ~/.agents/skills/task-tickets
```

templates 不属于 skills 生态：官方模板内核预置、无需安装；本仓的实验性/社区模板手动 symlink 到 `~/.yomi/agents/`。

yomi 读 `~/.agents/skills/` 与项目内 `.agents/skills/`（项目覆盖全局），symlink 原生支持。
