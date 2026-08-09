# yomi-extensions

[yomi](https://github.com/Crescent617/yomi) harness 的官方扩展资产库——skills、agent templates，以及未来的更多扩展形态。设计文档见主仓 [`docs/design/agent-harness.md`](https://github.com/Crescent617/yomi/blob/main/docs/design/agent-harness.md)。

## 内容

| 类型 | 资产 | 说明 |
|---|---|---|
| skill | [`task-board/`](task-board/SKILL.md) | 共享任务板约定：`.yomi/board/` 目录、claim 协议、状态机、协调者聚合姿势 |

规划中：`agent-templates` skill（subagent 模板约定）、`janitor` skill（后台策展，暂缓）、`templates/`（内置 agent 模板：planner/builder/reviewer）。随主仓 P1–P3 落地逐步放出。

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

templates 不属于 skills 生态，安装走手动 symlink 到 `~/.agents/agents/`。

yomi 读 `~/.agents/skills/` 与项目内 `.agents/skills/`（项目覆盖全局），symlink 原生支持。
