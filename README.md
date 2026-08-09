# yomi-extensions

[yomi](https://github.com/Crescent617/yomi) harness 的官方扩展资产库——skills、agent templates，以及未来的更多扩展形态。设计文档见主仓 [`docs/design/agent-harness.md`](https://github.com/Crescent617/yomi/blob/main/docs/design/agent-harness.md)。

## 内容

| 类型 | 资产 | 说明 |
|---|---|---|
| skill | [`task-board/`](task-board/SKILL.md) | 共享任务板约定：`.yomi/board/` 目录、claim 协议、状态机、协调者聚合姿势 |
| skill | [`agent-templates/`](agent-templates/SKILL.md) | subagent 角色模板（ROLE.md）的选用、编写与策展纪律 |

规划中：`janitor` skill（后台策展，暂缓）。官方内置模板 planner/builder/reviewer 预置在 yomi 内核（`crates/kernel/src/agent_tmpl/`），不在此仓。

## 安装

skills 用生态通用 CLI（默认 symlink 进 `~/.agents/skills/`，yomi 原生可读）：

```bash
npx skills add Crescent617/yomi-extensions --list    # 预览
npx skills add Crescent617/yomi-extensions -g        # 全局安装全部
npx skills add Crescent617/yomi-extensions -g --skill task-board   # 只装单个
```

或手动：

```bash
git clone https://github.com/Crescent617/yomi-extensions ~/repos/yomi-extensions
ln -s ~/repos/yomi-extensions/task-board ~/.agents/skills/task-board
```

templates 不属于 skills 生态：官方模板内核预置、无需安装；本仓的实验性/社区模板手动 symlink 到 `~/.yomi/agents/`。

yomi 读 `~/.agents/skills/` 与项目内 `.agents/skills/`（项目覆盖全局），symlink 原生支持。
