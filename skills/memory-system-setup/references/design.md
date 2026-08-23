# Memory block 设计理由

改 SKILL.md §1 的 memory block 前必读——每条写法都有出处：

- **Append-only is the root of trust** — history can't be silently revised; errors get corrections, not edits. That stream lives in worklog/; diary/ is the one curated layer above it. Profiles (friend/, group/) are the other exception: they hold current state, not history — what goes stale moves to archive.md.
- **Raw first, narrative second** — the worklog guarantees nothing is lost; the diary guarantees someone can actually read it. The janitor is the bridge: it reads the raw stream every morning anyway, so summarizing costs no extra context.
- **NOW.md is a register, not a cache** — it holds work no slower tier has yet; the close-out-via-worklog rule keeps the append-only root of trust intact.
- **Sources, not snapshots** — volatile facts (statuses, schedules) don't rot into wrong facts.
- **"Recall before asking" is a command**, not an aspiration — it builds the retrieval habit.
- **Categories emerge on demand** — dream/ and janitor/ themselves split off this way.
