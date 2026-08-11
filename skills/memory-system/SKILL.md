---
name: memory-system
description: Bootstrap a persistent memory + self-evolution system for an agent workspace. Use when setting up memory for a new agent or workspace, or configuring dream/janitor crons.
---

# Memory System

Bootstrap a memory + self-evolution system for a fresh agent workspace. Three parts: what the system prompt (or AGENTS.md) says, how `memory/` is laid out and searched, and two resident crons — **dream** diverges (makes connections), **janitor** converges (consolidates knowledge).

## 1. The memory block (system prompt / AGENTS.md)

The constitution of the system — copy it verbatim into the system prompt or the workspace `AGENTS.md`:

```markdown
## Memory

Memory persists under ./memory/:

- ./memory/diary/YYYY-MM-DD.md: the default note stream — free-form, append-only, one entry
  per time heading (e.g. ## 14:30). Record anything: events, observations, people, project
  threads, todos. Append only, never rewrite; correct a mistake by appending a correction
  entry at the end. Terse — no pasted conversations or code dumps.
- ./memory/contacts.md: ID lookup table (Lark open_id, bot app_id, GitLab id, ...), kept as
  a structured table. Consult before DMing, @-mentioning, or resolving a sender; record new
  IDs as they surface.
- ./memory/lesson.md: my behavioral lessons, one line each — date + lesson + source.
- ./memory/friend/, ./memory/group/: living profiles of people and groups, one file per
  subject, holding only current info — update in place as knowledge deepens, add files for
  new subjects, and move superseded facts to archive.md instead of deleting them.
- ./memory/archive.md: append-only archive. Stale entries move here (source + archive date
  noted) instead of being deleted. Never pruned; grep it, never read it whole.
- Volatile facts with an authoritative source elsewhere (requirement progress, MR status,
  schedules): cite the source, never copy a snapshot.
- Search memory first: .agents/skills/memory-system/scripts/recall <keyword> (capped rg -i
  over memory/). Recall before asking a human.
- When notes on one theme pile up, split them into a dedicated file — categories emerge on
  demand, never prescribed upfront.
```

If this skill is installed globally rather than into the workspace, substitute `~/.agents/skills/memory-system/` for `.agents/skills/memory-system/` throughout (recall path, prompt files).

Why it is written this way:

- **Append-only is the root of trust** — history can't be silently revised; errors get corrections, not edits. Profiles (friend/, group/) are the exception: they hold current state, not history — what goes stale moves to archive.md.
- **Sources, not snapshots** — volatile facts (statuses, schedules) don't rot into wrong facts.
- **"Recall before asking" is a command**, not an aspiration — it builds the retrieval habit.
- **Categories emerge on demand** — dream/ and janitor/ themselves split off this way.

## 2. Directory + recall

```bash
mkdir -p memory/diary memory/dream memory/janitor memory/friend memory/group
touch memory/contacts.md memory/lesson.md memory/archive.md
```

recall ships with this skill at `scripts/recall` — a capped ripgrep over `memory/`:

- evergreen files (contacts / lesson / archive / friend / group) first, capped at 30 lines;
- dated files (diary / dream) in reverse-date order, capped at 50 lines — recent first;
- per-file cap of 20 matches, long lines truncated at 200 chars;
- root resolution: `$RECALL_ROOT`, else walk up from cwd to the first `memory/`.

## 3. The crons

Create each with the command under its heading (5-field expression, local time), under the fixed names `dream` and `janitor` — job names are unique and create has ensure semantics, so re-running setup never spawns duplicates. `--session` is left unset so each job gets a dedicated session — the main session is never disturbed. `{{date}}` in each prompt expands to the run date.

### dream — daily 03:33 (`33 3 * * *`)

Goal-less free association, producing a dream log. Prompt: [prompts/dream.txt](prompts/dream.txt).

```bash
yomi cron create --name dream --schedule "33 3 * * *" \
  --message "$(cat .agents/skills/memory-system/prompts/dream.txt)"
```

Design notes: the "no goals, tangents welcome" step is the soul — give a dream a goal and it degenerates into a daily report. Sleep-talk is "may", never "must"; with no broadcast channel, delete that step from the prompt before creating the job.

### janitor — daily 05:55 (`55 5 * * *`)

Memory housekeeping + self-evolution (distilling repeated workflows into skills). Prompt: [prompts/janitor.txt](prompts/janitor.txt).

```bash
yomi cron create --name janitor --schedule "55 5 * * *" \
  --message "$(cat .agents/skills/memory-system/prompts/janitor.txt)"
```

Design notes: the iron rules come first — an autonomous cron gets its read/write boundaries hard-coded up front. The "Suggestions" section gives uncertain changes an outlet. The mandatory "nothing today" file makes cron liveness checkable.

## Verification

- [ ] Ask "how did we decide X before?" — the agent runs recall first instead of guessing;
- [ ] `yomi cron list` shows exactly one `dream` and one `janitor`;
- [ ] diary files only grow by appends — no rewrites;
- [ ] after the first scheduled runs, `memory/dream/` and `memory/janitor/` hold dated files;
- [ ] the janitor report contains a "Suggestions" section (even an empty one).

## Known pitfalls

- A cron's manual `trigger` (run immediately) is suspected broken — verify by waiting for the real schedule, or run the flow by hand once.
- The janitor's transcript reading must stay capped (user messages in full + assistant head/tail) or its context explodes.
