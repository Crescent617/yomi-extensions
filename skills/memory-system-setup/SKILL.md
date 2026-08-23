---
name: memory-system-setup
description: 给新 workspace 一次性 bootstrap 持久记忆系统（memory/ 目录 + recall 检索 + dream/janitor 两个常驻 cron）。手动触发：要搭建时说"装记忆系统"。
disable-model-invocation: true
---

# Memory System

Bootstrap a memory + self-evolution system for a fresh agent workspace. Three parts: what the system prompt (or AGENTS.md) says, how `memory/` is laid out and searched, and two resident crons — **dream** diverges (makes connections), **janitor** converges (consolidates knowledge). Setup is one-shot per workspace — the result references nothing in this skill.

## 1. The memory block (system prompt / AGENTS.md)

The constitution of the system — copy it verbatim into the system prompt or the workspace `AGENTS.md`:

```markdown
## Memory

Memory persists under ./memory/:

- ./memory/NOW.md: the L0 register — important in-flight work only, one terse line per
  task, tagged with the session/chat id doing it. Small chores and short-lived runs
  (dream/janitor) stay out. Claim a line when starting, update in place, and close out via
  the worklog: a line leaves only after its outcome (completion/abort/handoff) is appended
  to today's worklog.
- ./memory/worklog/YYYY-MM-DD.md: the raw record stream — free-form, append-only, one
  entry per time heading (e.g. ## 14:30). Record anything: events, people, project
  threads, todos. Never rewrite; correct by appending a correction entry. Terse — no
  pasted conversations or code dumps.
- ./memory/contacts.md: ID lookup table (Lark open_id, bot app_id, GitLab id, ...).
  Consult before DMing, @-mentioning, or resolving a sender; record new IDs as they
  surface.
- ./memory/lesson.md: behavioral lessons, one line each — date + lesson + source.
- ./memory/friend/, ./memory/group/: living profiles of people and groups, one file per
  subject, current info only — update in place, add files for new subjects, move
  superseded facts to archive.md. Promotion bar: ≥2 distinct interactions or a clear
  role earns a friend file; thin contacts stay one-liners in contacts.md.
- ./memory/archive.md: append-only archive for superseded entries (source + archive
  date noted). Never pruned; grep it, never read it whole.
- Volatile facts with an authoritative source elsewhere (requirement progress, MR
  status): cite the source, never copy a snapshot.
- Search memory first: memory/recall <keyword>. Recall before asking a human.
- When notes on one theme pile up, split them into a dedicated file — categories emerge on
  demand.
```

The memory block uses the recall path installed in §2 (default `memory/recall`). If this skill is installed globally rather than into the workspace, substitute `~/.agents/skills/memory-system-setup/` for `.agents/skills/memory-system-setup/` in the setup commands below. Design rationale for the block: [references/design.md](references/design.md) — read it before editing the block.

## 2. Directory + recall

```bash
mkdir -p memory/worklog memory/diary memory/dream memory/janitor memory/friend memory/group memory/knowledge
printf '# Now — important in-flight work only, one terse line each\n<!-- - [sess_or_chat_id] MM-DD — what (where); a line leaves only via a diary entry -->\n' > memory/NOW.md
printf '| name | platform | id | note |\n| --- | --- | --- | --- |\n' > memory/contacts.md
printf '# Lessons\n\n<!-- one line each: YYYY-MM-DD — lesson (source) -->\n' > memory/lesson.md
touch memory/archive.md
install -m 755 .agents/skills/memory-system-setup/scripts/recall memory/recall
```

Seeded headers keep the first writer from inventing a schema of its own. If the workspace is a git repo, add `memory/` to `.gitignore` — these are private notes, not project files.

recall ships with this skill at `scripts/recall`; the setup block installs it into the workspace — `memory/recall` is the default (recall searches only `*.md`, so it never greps itself), but any in-workspace path works if the memory block matches. Once copied, the system no longer depends on the skill staying installed. It runs a capped ripgrep over `memory/`, in three tiers:

- evergreen (contacts / lesson / friend / group / knowledge / emergent top-level notes) first, capped at 30 lines;
- dated files (diary / worklog / dream / janitor) in reverse-date order, capped at 50 lines — recent first;
- cold (archive.md) last, capped at 30 lines — it stores superseded info, so it ranks below everything current;
- per-file cap of 20 matches, long lines truncated at 200 chars;
- root resolution: `$RECALL_ROOT`, else walk up from cwd to the first `memory/`.

## 3. The crons

Two creation paths:

- **cron tool (preferred)** — from a session running in the workspace, have the agent create both jobs from the prompt files. The dedicated session inherits the caller's working dir, so the prompts' relative `memory/` paths resolve correctly.
- **CLI** — the commands under each heading. The RPC path has no caller session to follow, so the dedicated session lands in the daemon's default workspace (`<data_dir>/workspace`); use this only when that *is* the target workspace. (`-d/--dir` is accepted but ignored by `yomi cron`.)

Either way: fixed names `dream` and `janitor` (unique + ensure semantics — re-running setup never spawns duplicates), `--session` unset so each job gets its own dedicated session and the main session is never disturbed, `{{date}}` expands to the run date, schedules are 5-field expressions in local time. Later edits to a prompt file don't propagate to an existing job — recreate it (delete + create).

Language: the shipped prompts are Chinese. If the deployment's language isn't Chinese, translate the message at creation time (resolve from the conversation) — a detached cron session has no conversation to inherit its language from, and a prompt in the user's language makes every output — dream log, janitor report, memory edits — come out in that language by default. Translate faithfully: iron rules, caps, and may/must distinctions must survive; translate, don't paraphrase.

### dream — daily 03:33 (`33 3 * * *`)

Goal-less free association, producing a dream log. Prompt: [prompts/dream.txt](prompts/dream.txt).

```bash
yomi cron create --name dream --schedule "33 3 * * *" \
  --message "$(cat .agents/skills/memory-system-setup/prompts/dream.txt)"
```

Design notes: the "no goals, tangents welcome" step is the soul — give a dream a goal and it degenerates into a daily report. Sleep-talk is "may", never "must"; with no broadcast channel, delete that step from the prompt before creating the job.

### janitor — daily 05:55 (`55 5 * * *`)

Memory housekeeping + self-evolution (distilling repeated workflows into skills). Prompt: [prompts/janitor.txt](prompts/janitor.txt).

```bash
yomi cron create --name janitor --schedule "55 5 * * *" \
  --message "$(cat .agents/skills/memory-system-setup/prompts/janitor.txt)"
```

Design notes: the iron rules come first — an autonomous cron gets its read/write boundaries hard-coded up front. The "Suggestions" section gives uncertain changes an outlet. The mandatory "nothing today" file makes cron liveness checkable. The NOW.md sweep is the dead-session safety net: an orphaned line gets reconstructed from its transcript tail and closed out via the worklog. The diary step is the other half of its job: the raw stream stays in worklog/, but memory needs a face — one narrative page a day a human would actually read.

## Verification

- [ ] Ask "how did we decide X before?" — the agent runs recall first instead of guessing;
- [ ] every departed NOW.md line left a same-day worklog entry;
- [ ] `yomi cron list` shows exactly one `dream` and one `janitor`, and `yomi cron get <id>` shows a non-empty message in the user's language, iron rules and caps intact — a failed `cat` still creates the job with an empty prompt, and the unique name then blocks re-creation;
- [ ] worklog files only grow by appends — no rewrites;
- [ ] after the first scheduled runs, `memory/dream/` and `memory/janitor/` hold dated files, and `memory/diary/` holds a narrative page for the day just ended;
- [ ] the janitor report contains a "Suggestions" section (even an empty one).

## Known pitfalls

- Job names are unique **daemon-wide**: one daemon hosts one memory system as shipped. A second workspace's `dream` create short-circuits to the first workspace's job — for a second instance, derive the namespace from the workspace root directory name (`~/repos/foo` → `dream:foo`, `janitor:foo`): a fixed derivation, so re-setup computes the same name; same-basename workspaces still collide.
- The janitor's `yomi session list/cat` calls need the yomi CLI on the cron session's PATH.
- A cron's manual `trigger` (run immediately) is suspected broken — verify by waiting for the real schedule, or run the flow by hand once.
- The janitor's transcript reading must stay capped or its context explodes — don't drop the cap when editing the prompt.
- Deleting a NOW.md line without a worklog entry is silent work loss — the close-out protocol is the integrity rule; without the janitor sweep, a session that dies mid-task leaves NOW.md to rot into a second worklog.
