# yomi-extensions

[yomi](https://github.com/Crescent617/yomi) harness 的官方扩展资产库——skills、agent templates，以及未来的更多扩展形态。设计文档见主仓 [`docs/design/agent-harness.md`](https://github.com/Crescent617/yomi/blob/main/docs/design/agent-harness.md)。

## 内容

skills 住 [`skills/`](skills/) 子目录，其他资产类型（如模板）各有顶层目录：

| 类型 | 资产 | 说明 |
|---|---|---|
| skill | [`skills/task-tickets/`](skills/task-tickets/SKILL.md) | 工单约定：`.yomi/tickets/` 目录、派单/签收/状态机、聚合验收、僵尸回收 |
| skill | [`skills/agent-templates/`](skills/agent-templates/SKILL.md) | subagent 角色模板（ROLE.md）的选用、编写与策展纪律 |

规划中：`janitor` skill（后台策展，暂缓）。官方内置模板 planner/reviewer/explorer 预置在 yomi 内核（`crates/kernel/src/agent_tmpl/`），不在此仓。

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
