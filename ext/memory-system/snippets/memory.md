# memory-system 使用约定

持久记忆的主目录是 daemon 默认 workspace 下的 `memory/`——即
`$YOMI_DATA_DIR/workspace/memory`（本机 `~/.yomi/workspace/memory`）。
各项目目录不另建记忆库；所有写操作一律落在主目录。下文 `./memory/`
均指主目录。`recall` 检索自动定位主库（`$RECALL_ROOT` →
`$YOMI_DATA_DIR/workspace` → 从当前目录向上找 `memory/`），在任何
工作目录都能用。

- `NOW.md`：在途工作寄存器——只记重要在办事项，一行一条，
  标注承运的 session/chat id。小杂事与短周期运行（dream/janitor）不进。
  开工占行、原地更新；一行只在当天 worklog 追记了结局
  （完成/中止/转手）后才移除。
- `worklog/YYYY-MM-DD.md`：原始记录流——自由格式、只追加，
  每条一个时刻标题（如 `## 14:30`）。记事件、人物、项目线、待办。
  不重写；订正用追加订正条。要简——不贴对话与代码。
- `contacts.md`：ID 查表（Lark open_id、bot app_id、GitLab id
  等）。发私信、@人、解析发送者身份前先查；新 ID 随手登记。
- `lesson.md`：行为教训，一行一条——日期 + 教训 + 来源。
- `friend/`、`group/`：人物与群的活档案，一主体一
  文件，只留当前信息——原地更新、新主体新建文件、被取代的事实挪去
  archive.md。建档线：≥2 次不同互动或有明确角色才建 friend 文件；
  薄联系人留在 contacts.md 一行。
- `archive.md`：只追加的归档（附来源 + 归档日期）。不修剪；
  用 grep 查，不整读。
- `knowledge/`：主题知识库——从 worklog/diary/会话沉淀稳定
  知识（项目背景、环境配置、可复用流程、坑的修复方案），一主题一
  文件；知识加深原地更新，过时事实挪 archive.md。
- 有权威出处 elsewhere 的易变事实（需求进度、MR 状态）：引用出处，
  不抄快照。
- 同一主题的笔记堆多了就拆专文件——分类按需涌现。
- 问人之前先搜记忆：`recall <关键词>`。

主目录还没初始化时，跑一次 `memory-init`（幂等：缺的目录与种子文件
才建，已有的不碰）。

检索命令 `recall` 由 memory-system 扩展提供（已在 PATH）：分层上限
检索主目录——NOW.md 最先（10 行上限），evergreen 文件其次（30 行），
日期型目录（worklog/diary/dream/janitor）按日期新→旧（50 行），
archive.md 最后（30 行）；单文件 20 条命中、长行截 200 字符。
