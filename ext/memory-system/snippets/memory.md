# memory-system 使用约定

持久记忆在本 workspace 的 `./memory/` 目录：

- `./memory/NOW.md`：在途工作寄存器——只记重要在办事项，一行一条，
  标注承运的 session/chat id。小杂事与短周期运行（dream/janitor）不进。
  开工占行、原地更新；一行只在当天 worklog 追记了结局
  （完成/中止/转手）后才移除。
- `./memory/worklog/YYYY-MM-DD.md`：原始记录流——自由格式、只追加，
  每条一个时刻标题（如 `## 14:30`）。记事件、人物、项目线、待办。
  不重写；订正用追加订正条。要简——不贴对话与代码。
- `./memory/contacts.md`：ID 查表（Lark open_id、bot app_id、GitLab id
  等）。发私信、@人、解析发送者身份前先查；新 ID 随手登记。
- `./memory/lesson.md`：行为教训，一行一条——日期 + 教训 + 来源。
- `./memory/friend/`、`./memory/group/`：人物与群的活档案，一主体一
  文件，只留当前信息——原地更新、新主体新建文件、被取代的事实挪去
  archive.md。建档线：≥2 次不同互动或有明确角色才建 friend 文件；
  薄联系人留在 contacts.md 一行。
- `./memory/archive.md`：只追加的归档（附来源 + 归档日期）。不修剪；
  用 grep 查，不整读。
- 有权威出处 elsewhere 的易变事实（需求进度、MR 状态）：引用出处，
  不抄快照。
- 同一主题的笔记堆多了就拆专文件——分类按需涌现。
- 问人之前先搜记忆：`recall <关键词>`。

当前 workspace 还没有 `./memory/` 目录时，先跑一次 `memory-init`
（幂等：缺的目录与种子文件才建，已有的不碰）。

检索命令 `recall` 由 memory-system 扩展提供（已在 PATH）：分层上限
检索本 workspace 的 `./memory/`——NOW.md 最先（10 行上限），evergreen
文件其次（30 行），日期型目录（worklog/diary/dream/janitor）按日期新→旧
（50 行），archive.md 最后（30 行）；单文件 20 条命中、长行截 200 字符。
从当前目录向上找第一个含 `memory/` 的目录作为根。
