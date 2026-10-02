# memory-system 迁移指南：从 memory-system-setup skill 到扩展包

写给还在用旧 skill 形态记忆系统的用户（装过 `memory-system-setup`
skill，从没跑过 `yomi extension install`）的维护 agent。按顺序执行，
每步有验证点，异常停在该步排查。

## 旧形态判定（满足即适用）

- `yomi extension list` 里没有 memory-system
- 记忆数据在 **workspace 下的 `memory/`**（如 `~/.yomi/workspace/memory/`，
  由 skill 按 workspace 引导），不在 `~/.yomi/memory/`
- `yomi cron list` 里有裸名 `dream` / `janitor` 两条 job
- workspace `AGENTS.md` 有一段 `## Memory` 纪律文字

新旧核心差异：**旧形态数据跟着 workspace 走，新形态锚定
`$YOMI_DATA_DIR/memory`（即 `~/.yomi/memory/`）**——所以迁移有两件
必做的事：搬数据、清老 cron。

## 迁移步骤

```bash
# 1. 升级 yomi（CLI 与 GUI 都要，扩展系统需要 ≥ 0.11.0）
brew upgrade yomi && brew upgrade --cask yomi-app
yomi --version        # 验证：≥ 0.11.0

# 2. 迁移记忆数据：workspace/memory → ~/.yomi/memory（扩展的锚定点）
ls ~/.yomi/memory 2>/dev/null && { echo "目标已存在，先人工合并"; exit 1; }
mv ~/.yomi/workspace/memory ~/.yomi/memory

# 3. 删掉旧 recall 脚本（检索改由扩展的 recall 命令提供）
rm -f ~/.yomi/memory/recall

# 4. 装扩展（init 钩子幂等：缺的种子文件才建，刚迁的数据一个不碰）
yomi extension install Crescent617/yomi-extensions/ext/memory-system
```

第 2 步若目标已存在（部分迁移过）：用 `rsync -a ~/.yomi/workspace/memory/ ~/.yomi/memory/`
合并，逐文件核对冲突（NOW.md、当天 worklog 重点看），确认无误后删除
workspace 下的旧目录。

第 4 步若报 `mount conflict: ... bin/recall ...`：老的 recall 被手动
放进了 `~/.yomi/bin/` 占槽位，挪走后重跑 install。

## 清理老 cron（不做会双跑）

扩展装好后会产生 `ext:memory-system:dream` 和 `ext:memory-system:janitor`。
旧裸名的两条还在的话，每天 janitor/dream 各跑两遍：

```bash
yomi cron list                 # 找裸名 dream / janitor（非 ext: 前缀）
yomi cron delete <旧 job id>   # 两条都删
```

## 清理旧痕迹

1. workspace `AGENTS.md` 的 `## Memory` 段：整段删除（扩展的
   snippet 已把纪律拼进每个会话的系统提示词，留着重复占位）。其他
   内容不动。
2. `rm -rf ~/.agents/skills/memory-system-setup`：skill 已被扩展取代，
   留着会让 agent 读到过时指引。

## 验证（全部通过才算完）

```bash
yomi extension list
# 期望：memory-system  1.0.1  ok  …  2 cron, 0 hooks, 1 bins, 1 snippets
```

- install 输出有 `init scripts/memory-init ran: memory system ready at ...`
- `ls ~/.yomi/workspace/memory` 不存在（旧目录已迁走）；`~/.yomi/memory/` 下旧文件原样在（抽查最近一期 worklog）
- `recall <一个只存在于旧数据的词>` 能命中——证明数据迁移后检索链路通
- `yomi cron list | grep -E 'dream|janitor'`：只剩 `ext:memory-system:` 前缀的两条，裸名零残留
- `yomi rpc preview_system_prompt | grep "Extension: memory-system"` 有输出
- workspace AGENTS.md 不再有 `## Memory` 段

## 已是扩展 1.0.0 的用户（yomi 0.10.55/56 期间装的）

`yomi extension remove memory-system` → 若提示目录 foreign 拒删，
`rm -rf ~/.yomi/extensions/memory-system` → 重新 install。原因：那两版
的安装记录是老格式（包内 ext.lock），新版注册表不再收养。

## 常见问题

| 现象 | 处置 |
|---|---|
| 第 2 步目标已存在 | 按 rsync 合并路径走，重点核对 NOW.md 与当天 worklog |
| install 报槽位 occupied / mount conflict | 老脚本占了 `~/.yomi/bin` 槽位，挪走后重跑 |
| 迁移后 recall 搜不到旧记忆 | 第 2 步没迁对位置；确认数据在 `~/.yomi/memory/` 且第 3 步删的是脚本不是数据 |
| 新旧 cron 同时出现在 list | 清理老 cron 那步没做完 |
| 想回退 | `yomi extension remove memory-system`；记忆数据在 `~/.yomi/memory/`，纯 markdown 无格式锁，回退零成本 |
