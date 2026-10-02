# memory-system 升级指南（1.0.0 → 1.0.1，配 yomi ≥ 0.11.0）

写给老用户（memory-system 1.0.0，yomi ≤ 0.10.56）的维护 agent：
按顺序执行，每步有验证点，异常就停在该步排查，不要跳步。

## 要不要升级

满足任一即需要：

- `yomi extension list` 里 memory-system 版本是 1.0.0 或 health 是 `foreign`
- `yomi --version` 低于 0.11.0

## 变化清单（执行前读一遍）

1. **`memory-init` 不在 PATH 上了**。它是一次性初始化工具，不该占所有
   子进程的 PATH——已挪到包内 `scripts/`，改由 yomi 的 `ext.init` 安装
   钩子在装完/刷新后自动执行（幂等）。旧习惯直接调 `memory-init` 会
   command not found；正确做法是**不手动调**，需要手动重建主库时用全
   路径 `extensions/memory-system/scripts/memory-init`。
2. **安装记录合并为单文件注册表** `extensions/ext.lock`（yomi 0.10.57
   起）。1.0.0 的安装记录在包目录内的 ext.lock 里，新版不再自动收养
   ——所以下面要 remove + 重装，而不是直接 reinstall。
3. **cron 刷新语义**（yomi 0.11.0 起）：重装会更新 job 的消息文本，
   你手改过的 schedule 不被冲掉。memory-system 的 dream/janitor 消息
   更新后重装即生效，不用再删 job。
4. **snippet 表述更新**：记忆规则段现在写明"安装时自动初始化主库"。

## 升级步骤

```bash
# 1. 升级 yomi（CLI 与 GUI 都要）
brew upgrade yomi && brew upgrade --cask yomi-app
yomi --version        # 验证：≥ 0.11.0

# 2. 卸载旧版扩展（cron/前缀清扫 + 挂载摘除不依赖注册表，都能清掉）
yomi extension remove memory-system

# 3. 上一步若提示目录因无注册表条目被拒删（foreign 保护），手动删掉：
ls ~/.yomi/extensions/memory-system 2>/dev/null && rm -rf ~/.yomi/extensions/memory-system

# 4. 装新版
yomi extension install Crescent617/yomi-extensions/ext/memory-system
```

## 验证（全部通过才算完）

```bash
yomi extension list
# 期望：memory-system  1.0.1  ok  …  2 cron, 0 hooks, 1 bins, 1 snippets
```

- install 输出里有一行 `init scripts/memory-init ran: memory system ready at ...`——钩子自动初始化过主库（已有主库则幂等不动）
- `recall 发版` 有输出（bin 命令正常）
- `yomi cron list | grep memory-system` 有 dream 和 janitor 两条且 active
- 若用户改过这两条 cron 的触发时刻，确认时刻仍是用户值（refresh 语义保留 schedule）

## 常见问题

| 现象 | 处置 |
|---|---|
| remove 报目录留下/foreign | 预期行为（注册表无旧格式条目）。确认是 `~/.yomi/extensions/memory-system` 后手动删，回到步骤 4 |
| install 报槽位 occupied | 步骤 3 没做干净，删掉残留目录重跑 |
| `memory-init: command not found` | 旧习惯调用。不需要手动初始化；确需手动重建用包内全路径 |
| 旧 CLI 连新 daemon 报版本不匹配 | wire 协议已升 34，brew 升级 CLI 后再试 |
