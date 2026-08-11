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
printf '| name | platform | id | note |\n| --- | --- | --- | --- |\n' > memory/contacts.md
printf '# Lessons\n\n<!-- one line each: YYYY-MM-DD — lesson (source) -->\n' > memory/lesson.md
touch memory/archive.md
```

Seeded headers keep the first writer from inventing a schema of its own. If the workspace is a git repo, add `memory/` to `.gitignore` — these are private notes, not project files.

recall ships with this skill at `scripts/recall` — a capped ripgrep over `memory/`, in three tiers:

- evergreen (contacts / lesson / friend / group / emergent top-level notes) first, capped at 30 lines;
- dated files (diary / dream / janitor) in reverse-date order, capped at 50 lines — recent first;
- cold (archive.md) last, capped at 30 lines — it stores superseded info, so it ranks below everything current;
- per-file cap of 20 matches, long lines truncated at 200 chars;
- root resolution: `$RECALL_ROOT`, else walk up from cwd to the first `memory/`.

## 3. The crons

Two creation paths:

- **cron tool (preferred)** — from a session running in the workspace, have the agent create both jobs from the prompt files. The dedicated session inherits the caller's working dir, so the prompts' relative `memory/` paths resolve correctly.
- **CLI** — the commands under each heading. The RPC path has no caller session to follow, so the dedicated session lands in the daemon's default workspace (`<data_dir>/workspace`); use this only when that *is* the target workspace. (`-d/--dir` is accepted but ignored by `yomi cron`.)

Either way: fixed names `dream` and `janitor` (unique + ensure semantics — re-running setup never spawns duplicates), `--session` unset so each job gets its own dedicated session and the main session is never disturbed, `{{date}}` expands to the run date, schedules are 5-field expressions in local time. Later edits to a prompt file don't propagate to an existing job — recreate it (delete + create).

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
- [ ] `yomi cron list` shows exactly one `dream` and one `janitor`, and `yomi cron get <id>` shows a non-empty message — a failed `cat` still creates the job with an empty prompt, and the unique name then blocks re-creation;
- [ ] diary files only grow by appends — no rewrites;
- [ ] after the first scheduled runs, `memory/dream/` and `memory/janitor/` hold dated files;
- [ ] the janitor report contains a "Suggestions" section (even an empty one).

## Known pitfalls

- Job names are unique **daemon-wide**: one daemon hosts one memory system as shipped. A second workspace's `dream` create short-circuits to the first workspace's job — for a second instance, derive the namespace from the workspace root directory name (`~/repos/foo` → `dream:foo`, `janitor:foo`): a fixed derivation, so re-setup computes the same name; same-basename workspaces still collide.
- The janitor's `yomi session list/cat` calls need the yomi CLI on the cron session's PATH.
- `yomi session list` (no `-a`) matches sessions by exact working dir: subdirectory sessions are invisible, and a janitor in the wrong dir (CLI path landing in the daemon's default workspace) scans zero sessions and files "nothing today" forever.
- A cron's manual `trigger` (run immediately) is suspected broken — verify by waiting for the real schedule, or run the flow by hand once.
- The janitor's transcript reading must stay capped or its context explodes — don't drop the cap when editing the prompt.
