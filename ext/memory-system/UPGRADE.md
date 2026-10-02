# memory-system 迁移指南：从 skill 时代到扩展包

写给还在用旧形态记忆系统、**从没跑过 `yomi extension install`** 的
用户的维护 agent。旧形态 = 纪律文字在 workspace `AGENTS.md`、检索靠
`memory/recall` bash 脚本、janitor/dream cron 是手工建的自由命名 job。
新形态 = memory-system 扩展包（纪律进系统提示词、`recall` 命令上 PATH、
dream/janitor 随包收养）。**记忆数据零迁移**——扩展锚定的就是同一个
`~/.yomi/memory/`，init 钩子幂等，已有的文件一个不碰。

按顺序执行，每步有验证点，异常停在该步排查。

## 要不要迁移

满足全部即适用：

- `yomi extension list` 里没有 memory-system（或该命令不存在）
- `~/.yomi/memory/` 已存在（旧记忆数据要保留）

## 迁移步骤

```bash
# 1. 升级 yomi（CLI 与 GUI 都要，扩展系统需要 ≥ 0.11.0）
brew upgrade yomi && brew upgrade --cask yomi-app
yomi --version        # 验证：≥ 0.11.0

# 2. 装扩展（init 钩子幂等初始化：缺的种子文件才建，已有记忆不动）
yomi extension install Crescent617/yomi-extensions/ext/memory-system
```

install 若报 `mount conflict: ... bin/recall ...`：说明老的 recall
脚本被手动放进了 `~/.yomi/bin/` 占了槽位。把它挪走（或删了，扩展的
recall 已覆盖其功能）后重跑 install。

## 去重（不做会双份）

迁移后旧组件还在原地，逐项清理：

1. **旧 cron job**：`yomi cron list` 里找旧的 dream / janitor（名字
   不是 `ext:memory-system:*` 的那两条），`yomi cron delete <id>`。
   不删的话新旧双跑——每天两次 janitor 保洁、两次 dream。
2. **workspace `AGENTS.md` 的记忆纪律段**：删掉（扩展的 snippet 已把
   纪律拼进每个会话的系统提示词，留着重复占位）。只删记忆那一段，
   AGENTS.md 其他内容不动。
3. **旧 `memory/recall` 脚本**：`rm ~/.yomi/memory/recall`（recall
   命令已由扩展提供，旧脚本失去存在意义）。
4. **memory-system-setup skill**（如有）：删 `~/.agents/skills/
   memory-system-setup/`。该 skill 已被扩展包取代，留着会让 agent
   读到过时指引。

## 验证（全部通过才算完）

```bash
yomi extension list
# 期望：memory-system  1.0.1  ok  …  2 cron, 0 hooks, 1 bins, 1 snippets
```

- install 输出有 `init scripts/memory-init ran: memory system ready at ...`
- `recall 发版` 有输出（新 recall 正常）
- `yomi cron list | grep memory-system` 只有 `ext:memory-system:dream`
  和 `ext:memory-system:janitor` 两条且 active，旧命名的一条不剩
- `yomi rpc preview_system_prompt | grep "Extension: memory-system"` 有输出
- 抽查 `~/.yomi/memory/worklog/` 最近文件——旧数据原样在

## 已是扩展 1.0.0 的用户（yomi 0.10.55/56 期间装的）

`yomi extension remove memory-system` → 若提示目录 foreign 拒删，
`rm -rf ~/.yomi/extensions/memory-system` → 重新 install。原因：那两版
的安装记录是老格式（包内 ext.lock），新版注册表不再收养。

## 常见问题

| 现象 | 处置 |
|---|---|
| install 报槽位 occupied / mount conflict | 老脚本占了 `~/.yomi/bin` 槽位，挪走后重跑 |
| 迁移后 agent 还在引用旧 skill/脚本 | 检查去重第 3、4 步做净没有 |
| 旧 CLI 连新 daemon 报版本不匹配 | wire 协议已升 34，brew 升级 CLI 后再试 |
| 想回退 | `yomi extension remove memory-system`；记忆数据在 `~/.yomi/memory/`，扩展从不写死格式，回退零成本 |
