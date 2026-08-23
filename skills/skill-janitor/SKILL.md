---
name: skill-janitor
description: 技能库卫生治理：体检（条目数/索引体积/触发面）、台账对账清僵尸、归档冷 skill、update 安全检查。当 skill 越装越多需要整理/精简/清理技能库、怀疑有重复或失效条目、或全量 update 前体检时使用。
---

# Skill Janitor 技能库治理

治理对象是**库**不是单个 skill（写单个 skill 的规范见 writing-great-skills）。原则：机械部分照命令跑，判断题（合并/删除）列证据给用户拍板。

## 1. 体检

跑一遍，产出事实表（条目数、索引体积、超长名单、手动项）：

```bash
python3 - <<'EOF'
import os, re
def scan(root):
    rows = []
    if not os.path.isdir(root): return rows
    for d in sorted(os.listdir(root)):
        p = os.path.join(root, d, 'SKILL.md')
        if not os.path.isfile(p): continue
        fm = re.match(r'^---\n(.*?)\n---', open(p, encoding='utf-8', errors='replace').read(), re.S)
        if not fm: continue
        manual = 'disable-model-invocation' in fm.group(1)
        m = re.search(r'^description:\s*(.+?)(?=^\w+:|\Z)', fm.group(1), re.S | re.M)
        rows.append((d, len(' '.join(m.group(1).split())) if m else 0, manual))
    return rows
rows = []
seen = set()
for root in [os.path.expanduser('~/.agents/skills'), os.path.join(os.getcwd(), '.agents/skills')]:
    root = os.path.realpath(root)
    if root in seen: continue          # cwd 即 home 时两处是同一目录，去重
    seen.add(root)
    rows += scan(root)
print(f'{len(rows)} 个 skill，索引 ≈{sum(c for _, c, m in rows if not m)} 字符')
print('description 超 300 字符:', [f'{n}({c})' for n, c, _ in rows if c > 300])
print('手动触发:', [n for n, _, m in rows if m])
EOF
```

再通读一遍各 description，列出触发面重叠的对子（同一触发场景被多条覆盖）。

完成判据：给出条目数、索引字符数、超 300 名单、疑似重叠对。

## 2. 台账对账

`npx skills` 的全局台账在 `~/.agents/.skill-lock.json`（项目级为 `<project>/skills-lock.json`，同法处理），update 只认它。三类状态：

- **僵尸**（台账有 hash、磁盘无目录）：全量 update 时若源仓库有更新会被**复活**到磁盘——必须清零
- hash 为空的条目（well-known 系）：update 永远跳过，无害
- 磁盘有、台账无：手工 skill，update 不碰，正常

```bash
cp ~/.agents/.skill-lock.json ~/.agents/.skill-lock.json.bak-$(date +%Y%m%d)   # 先备份
python3 - <<'EOF'
import json, os
d = json.load(open(os.path.expanduser('~/.agents/.skill-lock.json')))['skills']
ondisk = set(os.listdir(os.path.expanduser('~/.agents/skills')))
z = sorted(n for n, m in d.items() if n not in ondisk and m.get('skillFolderHash'))
open('/tmp/zombies.txt', 'w').write('\n'.join(z)); print(len(z), '个僵尸')
EOF
while read -r s; do npx -y skills remove -g -y "$s" </dev/null >/dev/null 2>&1 || echo "FAIL: $s"; done < /tmp/zombies.txt
```

`</dev/null` 必须加——CLI 会读 stdin 的交互输入，`while read` 循环不加会被吃掉清单。

完成判据：重跑对账脚本，僵尸 = 0。

## 3. 归档纪律

- 冷 skill 用 `mv` 进 `~/.agents/skills-archive/`，留退路；归档是判断题，列出候选 + 理由（描述冷门、与活跃 skill 重叠）交给用户定
- 被归档 skill 若台账有条目，用 §2 的 remove 同步清掉，否则变成僵尸
- 完成判据：skills/ 里每条都在用，archive/ 里每条台账都无残留

## 4. 结构决策树（整改时的证据给法）

- 要**独立自动触发** → 必须是顶层 skill（kernel 只索引顶层）
- 子主题差异大、但总是经父级选后端（如按库选 API）→ 父级路由表 + sub-SKILL（子级不进索引，按需加载）
- 子主题总连着用 → 合并成 1 个 SKILL.md + `references/*.md`（references 永不进索引）
- 一次性/季节性 skill → frontmatter 加 `disable-model-invocation: true`，退出自动索引、按名可加载
- 有源 repo 的（如 yomi-ext）：改动在 repo 做，push 后 `npx skills update -g -y <name...>` 定向更新——update 比对的是**远端** hash，没 push 检不到差异；手工 skill 直接改磁盘

## 5. update 安全

- 全量 `skills update -g` 的前置条件：僵尸 = 0（见 §2）
- update 仅在源仓库 hash 变化时重装覆盖本地；源没变时本地手工改动保留
- 完成判据：update 后磁盘条数不变、无归档 skill 复活
