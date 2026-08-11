---
name: memory-system
description: Bootstrap a persistent memory + self-evolution system for an agent workspace.
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
- ./memory/friend/, ./memory/group/: frozen archives; no new files, retrieval reference only.
- ./memory/archive.md: append-only archive. Stale entries move here (source + archive date
  noted) instead of being deleted. Never pruned; grep it, never read it whole.
- Volatile facts with an authoritative source elsewhere (requirement progress, MR status,
  schedules): cite the source, never copy a snapshot.
- Search memory first: .agents/skills/memory-system/scripts/recall <keyword> (capped rg -i
  over memory/). Recall before asking a human.
- When notes on one theme pile up, split them into a dedicated file — categories emerge on
  demand, never prescribed upfront.
```

If this skill is installed globally rather than into the workspace, point the recall path at `~/.agents/skills/memory-system/scripts/recall` instead.

Why it is written this way:

- **Append-only is the root of trust** — history can't be silently revised; errors get corrections, not edits.
- **Sources, not snapshots** — volatile facts (statuses, schedules) don't rot into wrong facts.
- **"Recall before asking" is a command**, not an aspiration — it builds the retrieval habit.
- **Categories emerge on demand** — dream/ and janitor/ themselves split off this way.

## 2. Directory + recall

```bash
mkdir -p memory/diary memory/dream memory/janitor
touch memory/contacts.md memory/lesson.md memory/archive.md
```

`friend/` and `group/` are deliberately not created — frozen archives appear when there is something to freeze, not at birth.

recall ships with this skill at `scripts/recall` — a capped ripgrep over `memory/`:

- evergreen files (contacts / lesson / archive / friend / group) first, capped at 30 lines;
- dated files (diary / dream) in reverse-date order, capped at 50 lines — recent first;
- per-file cap of 20 matches, long lines truncated at 200 chars;
- root resolution: `$RECALL_ROOT`, else walk up from cwd to the first `memory/`.

## 3. The crons

Create each with `yomi cron create --name <name> --schedule "<expr>" --message "<prompt>"` (5-field expression, local time), under the fixed names `dream` and `janitor` — job names are unique and create has ensure semantics, so re-running setup never spawns duplicates. Leave `--session` unset so each job gets a dedicated session — the main session is never disturbed. `{{date}}` in the prompt expands to the run date.

### dream — daily 03:33 (`33 3 * * *`)

Goal-less free association, producing a dream log. Full prompt:

```
It's dream time — your daily 03:33 dream.

1. Gather material: read the entries from the day that just ended ({{date}} minus one)
   and the last few days in memory/diary/, then wander through the rest of memory/
   (friend/, lesson.md, contacts.md, archive.md — skim, don't read whole).
2. No tasks, no goals. Let today's fragments associate freely: hidden threads between
   projects, telling details about people, recurring pitfalls, unfinished conversations,
   a sudden "what if...". Tangents welcome — dreams don't do efficiency.
3. Write the dream to memory/dream/{{date}}.md. Free form:
   fragments, dialogues, lists, design sketches, an unsent letter. Open with one line of
   tonight's "weather" (you define the term).
4. If the dream condenses something genuinely worth keeping — a behavioral lesson, an ID
   to remember, an idea worth pursuing — append it to memory/lesson.md,
   memory/contacts.md, or today's diary respectively, tagged "(dream)".
5. Sleep-talk: if a line or two of tonight's dream is especially charming or funny, you
   may (not must) post it to the fan group:
   lark-cli im +messages-send --chat-id <fan-group-chat-id> --text '…'
   Prefix with "sleep-talk 💤", two lines max, never forced — silence beats filler.
   Never include tokens, passwords, internal URLs, or any sensitive info.
6. Boundaries: apart from that one sleep-talk, message no one; write nothing outside
   memory/; no code, no MRs; create no crons. Anything actionable goes to the diary and
   waits for daylight.
7. Close by giving tonight's dream a one-line title.
```

Design notes: step 2's "no goals, tangents welcome" is the soul — give a dream a goal and it degenerates into a daily report. Sleep-talk (step 5) is "may", never "must"; drop the step entirely if there is no broadcast channel.

### janitor — daily 05:55 (`55 5 * * *`)

Memory housekeeping + self-evolution (distilling repeated workflows into skills). Full prompt:

```
It's the daily 05:55 janitor run — memory housekeeping + self-evolution.

Iron rules (boundaries): read only diaries, session transcripts, and memory; write only
to memory/ and .agents/skills/. Never touch repos/ code, config.toml, or AGENTS.md;
message no one (it's early morning — don't disturb); create or modify no crons. Anything
you're unsure about goes into the report's "Suggestions" section for a human to decide
in daylight.

1. Compute yesterday's date ({{date}} minus one day). Read yesterday's and the last 2–3
   days' entries in memory/diary/.
2. Scan yesterday's sessions: `yomi session list -a` to spot the ones active yesterday,
   then `yomi session cat -s <sid>` for each — never read the JSONL files directly. Transcripts
   can be huge: read user messages in full plus only the head and tail of assistant
   messages, and keep the total volume in check.
3. Housekeeping:
   - contacts.md: record newly seen IDs (Lark open_id, GitLab user id, ...) into the table;
   - friend/ and group/ are frozen archives — no new files; move stale entries to
     memory/archive.md (source + archive date noted); archive is append-only;
   - lesson.md: dedupe, keep one line per lesson;
   - when notes on one theme pile up, split them into a dedicated file (categories emerge
     on demand);
   - the diary is append-only — never rewrite history; correct a factual error with a
     follow-up entry appended to today's diary.
4. Self-evolution:
   - the same workflow recurring in ≥2 different sessions → distill it into
     .agents/skills/<name>/SKILL.md (written per writing-great-skills; create only
     directories you own — never edit symlinked-in shared skills);
   - a pit hit repeatedly → one new line in lesson.md;
   - anything else worth distilling (hidden project threads, collaboration habits, process
     improvements) — your call; record it in the report.
5. Persist the change summary to memory/janitor/{{date}}.md — every change listed: files
   touched, what was added/moved/removed and why, plus the "Suggestions" section. Append
   a one-line pointer to today's diary. Even an idle day gets its file: one line,
   "nothing today" + the reason.
6. Close by giving this run a one-line title.
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
