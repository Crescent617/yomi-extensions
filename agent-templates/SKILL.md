---
name: agent-templates
description: subagent 角色模板（ROLE.md）的选用与编写。Use when 用 agent 工具派子任务需要选择 template、创建新的角色模板、或把 workspace 模板晋升到全局模板库时。
---

# Agent Templates

模板 = subagent 的角色定义（"这个 agent 是谁"）：角色定位 + 工具边界 + 输出契约。与 skill 的分工：skill 是"怎么做"的知识（读进自己的上下文），模板是"派谁做"（成为 subagent 的系统提示）。

## 选用模板

1. 准备用 agent 工具派活时，先 glob 模板目录：`~/.agents/agents/*/ROLE.md` 与工作区 `.agents/agents/*/ROLE.md`。内置 `planner` / `builder` / `reviewer` 随时可用，无需文件。
2. 只读 frontmatter 做选择：`description` 带负向线索（"不用于……"），先排除再匹配。拿不准时 `read` 正文。
3. 一次性角色不要套模板——直接把角色写进 agent 工具的 `prompt`。模板留给反复出现的角色。
4. 完成标准：`template` 参数传入选定名字，或明确决定 inline。

## 编写模板

格式：`<name>/ROLE.md`，YAML frontmatter + 角色正文。

```markdown
---
description: 一句话角色 + 何时用 + 何时别用（选择面，必备）
tools_block: [write, edit]   # 可选：只能收窄父 agent 的工具集，不能扩大
model_key: claude-opus       # 可选：缺省继承父 session
skills: [task-board]         # 可选：预加载 skill 白名单，缺省继承全部
---

角色正文：角色定位、工作方式、输出契约、边界。
```

1. 正文三件套：**工作方式、输出契约**（编号的结构化产出）、**边界**。保持短——知识走 skills，不进模板。
2. 能进 `tools_block` 的约束不写进正文：schema 级约束不漂移，prompt 级约束会。
3. 完成标准：description 含负向线索，正文 ≤60 行，frontmatter 合法。

## 策展纪律

**写哪：默认 workspace。** 自写角色永远先落 `.agents/agents/`——不存在"创建时选全局"的判断题。唯一例外：用户明确说"写到全局"。

理由（代价不对称）：该全局却写了 workspace，代价只是以后再晋升；该 workspace 却写了全局，它会出现在所有项目的选择面里造成污染，且全局库没有 git 审查面。默认值必须偏向 workspace。

**晋升：全局是晋升出来的，不是写出来的。** 满足全部条件才晋升到 `~/.agents/agents/`：

1. 跨项目证据：在两个以上项目里被实际用过（不是"感觉有用"）；
2. 零项目耦合：正文无绝对路径、无项目特有命令/约定；
3. 无近似全局角色（有就改旧的，不新建变体）；
4. 晋升动作告知用户（全局变更要留痕）。

模板会过期：模型变强后某些约束不再必要，定期回顾删减。
