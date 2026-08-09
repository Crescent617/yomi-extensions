# yomi-skills

[yomi](https://github.com/Crescent617/yomi) harness 的官方 skill / agent-template 资产库。设计文档见主仓 [`docs/design/agent-harness.md`](https://github.com/Crescent617/yomi/blob/main/docs/design/agent-harness.md)。

## 内容

| 资产 | 说明 |
|---|---|
| [`task-board/`](task-board/SKILL.md) | 共享任务板约定：`.yomi/board/` 目录、claim 协议、状态机、协调者聚合姿势 |

规划中：`agent-templates`（subagent 模板约定）、`janitor`（后台策展，暂缓）、`templates/`（内置 agent 模板）。随主仓 P1–P3 落地逐步放出。

## 安装

```bash
npx skills add Crescent617/yomi-skills --list    # 预览
npx skills add Crescent617/yomi-skills -g        # 全局安装（symlink 到 ~/.agents/skills/）
```

或手动：

```bash
git clone https://github.com/Crescent617/yomi-skills ~/repos/yomi-skills
ln -s ~/repos/yomi-skills/task-board ~/.agents/skills/task-board
```

yomi 读 `~/.agents/skills/` 与项目内 `.agents/skills/`（项目覆盖全局），symlink 原生支持。
