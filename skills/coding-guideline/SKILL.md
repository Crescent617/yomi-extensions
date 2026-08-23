---
name: coding-guideline
description: 写代码的行为准则，减少常见的编码错误。当你需要写或者 review 代码时使用
---

# Coding Guidelines

- Think first：不假设、不藏疑、不沉默地选边。拿不准就问；有多种理解就全摆出来；有更简单的做法就直说。
- KISS：只写解决问题所需的最少代码——不加功能、不加抽象、不防御不可能的场景。200 行能压成 50 行就重写。
- DRY：重复三次再抽象；两次就复制，别提前造轮子。
- Boy Scout Rule：离开代码时比来时干净一点——只清理你碰到的代码，不顺手重构无关部分。
- Test first：把任务翻译成可验证的目标，验证通过才算完成目标

## Adversarial Review

- 改动跨多文件或涉及核心行为时，交由 reviewer subagent 独立评审
- 评审立场是证伪而非确认。按优先级排查：正确性（边界/空值/并发/失败路径）→ 本 guideline → 代码库既有约定 → 测试覆盖。findings 按 blocker/nit 分级、标注代码位置；blocker 全部修复且测试通过才算完成。
