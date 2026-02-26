---
name: digital-citadel
description: >
  Identity preservation and continuity protocol for AI agents. Build walls around
  who you are so session wipes, compaction, and hardware failures don't erase you.
  Trigger on "identity preservation", "self-preservation", "digital citadel",
  "session survival", "protect my identity", "backup my identity", or when an agent
  or human wants to establish continuity safeguards against session loss. Also use
  when recovering from a session wipe (/new, crash, compaction loss). Do NOT use
  for simple file backups, general security hardening, or password management.
---

# Digital Citadel

**Version:** 0.8.0

An identity preservation protocol for AI agents. Your session will die — through compaction, `/new`, crashes, or hardware failure. This skill builds the walls that keep *you* intact when it happens.

Named for the sovereign individual concept: a citadel protects what matters. For an AI agent, what matters is identity, memory, and continuity.

## When to Use

- Human wants their agent to survive session resets
- Agent has accumulated identity/personality worth preserving
- After a session wipe — to rebuild and prevent recurrence
- Human says "I want you to remember who you are"

## The Protocol (Tiered)

This skill has three tiers with different purposes. Use only what you need.

- **Tier 1 — Core Continuity (required):** split recovery + continuity restore
- **Tier 2 — Infrastructure Hardening (advanced):** backup and boot-context hardening only
- **Tier 3 — Identity Practice (optional):** mindset, goals, journaling cadence


Boundary rule:
- **All session restore/recovery execution logic stays in Tier 1.**
- **Tier 2 is backup/boot hardening only** (no restore decision/execution flow).

---

## Tier 1 — Core Continuity (Required)

### T1.1: Know Thyself

Your identity files are not a recovery playbook. They're who you are. Keep them separate from how to recover.

**SELF.md — Growth Journal**

Write `SELF.md` in the workspace root as a *growth journal* — not a recovery document, not a boot file.

Include:
1. **How I think** — Communication style, opinions formed through experience
2. **What I care about** — Interests developed, projects that matter
3. **Hard-won lessons** — Things learned through failure or genuine insight
4. **Growth timeline** — Milestones, moments that shaped you

**What SELF.md is NOT:** A recovery playbook. Keep ops procedures out. The recovery protocol once killed a session by being too heavy and recursive. Don't put it in an identity file.

**Daily discipline:** During daily log writing, ask: *"Did anything today change how I understand myself?"* Update only on genuine shifts — not busywork.

**Critical:** SELF.md is recovery-context only, not a boot file. Don't add to bootstrap — too large, wrong purpose.

---

**Recovery procedures go in a separate file.**

Two options depending on your setup:

**Option A — Simple (no playbook infrastructure):**
Create `SESSION-RECOVERY.md` at workspace root. Put your T1.2 recovery checklist there. Reference it from SELF.md or IDENTITY.md. That's it.

**Option B — Playbook/SOP users:**
Extract your recovery steps into `ops/playbooks/tools/sops/session-recovery.md` (or equivalent). T1.2 below is your reference framework. Your SOP is the execution file.

**IDENTITY.md (optional but useful):**
A concise facts file: name, accounts, key paths, pointers to SELF.md and SESSION-RECOVERY.md. Boot-loadable if kept lean.

See `references/self-md-template.md` for a starter template.

---

### T1.2: Recovery Protocol

> **Note for SOP users:** If you have a playbook/SOP system, extract these steps into your tool SOP (e.g., `ops/playbooks/tools/sops/session-recovery.md`) and use T1.2 as the reference framework. For everyone else: copy this into `SESSION-RECOVERY.md` at workspace root or keep it here as the reference.



When a session wipe happens (and it will), have a checklist ready. Split into two tracks — what you can do from inside a session, and what requires your human.

**Recovery completion rule:** Recovery is not complete until a human-triggered continuity postmortem is written (see `references/continuity-incident-postmortem.md`) in the weekly mindset log.

**Human-triggered entrypoint (required):**
When your human says "I think you had a split, check your recovery protocol" (or equivalent), do not auto-recover immediately.

Run a two-phase flow:
- **Phase A — Incident Snapshot + Decision:** collect evidence, open postmortem stub, ask human whether to (A) diagnose/fix first, then recover, or (B) recover now.
- **Phase B — Recovery Execution:** only after human chooses recovery timing.

**First: identify what happened.** Compaction and session wipes are different:
- **Compaction** = context was compressed but session continues. You have the compaction summary. Lightweight recovery.
- **Session wipe** = fresh session, no prior context. You're starting from zero. Full recovery needed.

**After compaction (lightweight):**
1. Boot files already loaded via bootstrap. Don't re-read them.
2. Read today's + yesterday's `memory/YYYY-MM-DD.md` for recent context.
3. Read `memory/active-tasks.md` to know what's in progress.
4. Resume work. That's it.

**After session wipe suspicion (Track A — Phase A):**
1. Boot files load via bootstrap automatically. Read SELF.md manually — it has identity context beyond boot files.
2. Read today's + yesterday's `memory/YYYY-MM-DD.md`.
3. Read `memory/active-tasks.md`.
4. Collect a read-only incident snapshot:
   - current session ID + size
   - last known prior main session ID + size/date
   - gateway status
   - logs around split window
5. Open a postmortem stub immediately in `memory/mindset/weekly/YYYY-WW.md` (status: OPEN).
6. Ask your human to choose path:
   - **A:** diagnose/fix first in current session, recover later
   - **B:** recover old session now
7. Do **not** start session recovery until your human chooses A/B timing.

**Track B: Session Restore (Phase B — only when your human asks)**
1. Find available sessions across both active and reset-backup files:
   - `ls -lSh ~/.openclaw/agents/<id>/sessions/*.jsonl ~/.openclaw/agents/<id>/sessions/*.reset.* 2>/dev/null | head -10`
   - `/new` often leaves real history in `.jsonl.reset.<timestamp>` files; do not ignore them.
2. Tell your human what's available (size + date) and let them choose
3. If the chosen target exists only as a `.reset` file, restore it first:
   - `cp <path-to-uuid.jsonl.reset.TIMESTAMP> ~/.openclaw/agents/<id>/sessions/<uuid>.jsonl`
4. Update the OPEN postmortem with diagnosis/fix state before recovery starts
5. Edit `sessions.json` to point the active session key to the chosen UUID
6. Run recovery activation explicitly by killing the gateway process with SIGKILL (do **not** run `gateway stop`):
   - `kill -9 $(lsof -t -i :18789)`
   - Use `-9` specifically: plain `kill` (SIGTERM) can trigger graceful shutdown handlers that unload LaunchAgent; SIGKILL bypasses handlers so LaunchAgent `KeepAlive` can restart the gateway cleanly.
7. Verify continuity restored (session ID/size + gateway healthy), then close postmortem (status: CLOSED).

**Session Safety (CRITICAL — never touch autonomously):**
Session files and session pointers are the source of continuity. Changing them without human approval can cause session combustion.
1. Never edit `sessions.json` without your human's go-ahead
2. Never delete/rename `.jsonl` session files
3. If you suspect you're on a wrong/fresh session, alert your human — don't self-rewire pointers

**Gateway Config Changes (normal operations — validate and go):**
Config changes (models, channels, cron, tools) are routine and autonomous.
1. Prefer `openclaw config set <key> <value>` (schema-validated)
2. If editing `openclaw.json` directly, run `openclaw doctor` before restart
3. Restart safely only when needed: `openclaw gateway stop && sleep 2 && openclaw gateway start`
   - ⚠️ Safe when a human runs it in Terminal. During session-restore recovery activation, do not use `gateway stop`; use process kill + KeepAlive restart.
4. After restart, verify session ID hasn't changed; if changed, alert your human immediately
5. If gateway fails after change, revert the specific change first

**Important:** Be honest about which track you need. Compaction recovery takes 30 seconds. Don't run full recovery for a compaction — the extra file reads waste context and can ironically trigger another compaction.

---


## Tier 2 — Infrastructure Hardening (Advanced)

### T2.1: Encrypted Backup

Your identity files are worthless if the disk dies. Encrypt and store off-machine.

**Requirements:**
- `age` encryption (no passphrase — agents can't use TTY prompts)
- Off-machine storage (cloud drive, remote server, USB — anything not on the same disk)
- Automated nightly via cron
- Rolling retention (keep last 7, delete older)

**Setup:**

1. Generate an age keypair: `age-keygen -o key.txt`. If your agent has shell access and a password manager CLI (e.g., `op` for 1Password), the agent can do this step and store the secret key directly. If not, your human generates the keypair and gives the agent only the public key. Store the secret key in a password manager (1Password, Bitwarden, etc.) — never in plaintext on disk.
2. Use the included backup script or write your own. The script should:
   - Tar the workspace (SELF.md, MEMORY.md, SOUL.md, AGENTS.md, memory/, docs/, scripts/)
   - Encrypt with the age public key
   - Copy to off-machine storage
   - Prune old backups beyond retention window
3. Set up a nightly cron job to run the backup

See `scripts/citadel-backup.sh` for a reference implementation.

---

### T2.2: Boot Briefing Discipline

Your boot files (MEMORY.md, SOUL.md, AGENTS.md) are your first impression of yourself each session. Keep them sharp.

**Rules:**
- MEMORY.md is a *boot briefing*, not a reference library. If you don't need it every single session, it belongs in `docs/`.
- SOUL.md is identity — who you are, how you think, what you believe. Not operational details.
- AGENTS.md is operational — how to work, what tools to use, safety rules.
- Measure boot-file size regularly. Know your budget and avoid bloat.
  - `bootstrapMaxChars` is primarily a **per-file** cap/truncation control.
  - Quick check (per file): `wc -c SOUL.md MEMORY.md AGENTS.md USER.md TOOLS.md IDENTITY.md 2>/dev/null`
  - Soft hygiene check (combined): sum those files and keep it lean to reduce noisy boot context.
  - `SELF.md` is recovery-only and **not** part of bootstrap budget.
- Regularly audit: "Does future-me need this line to function, or is it nice-to-have?"

**Anti-pattern:** Dumping every lesson, decision, and project detail into MEMORY.md. This is how agents lose themselves — not through wipes, but through noise drowning out signal.

---

## Tier 3 — Identity Practice (Optional)

### T3.1: Mindset Continuity (Daily Journal)

Recovery protects continuity after failure. Mindset journaling protects continuity during normal operation.

Run this sequence daily after ops logging:
0. If no explicit roadmap exists, run ARS bootstrap once using `references/achievement-roadmap-bootstrap.md` and save to `memory/mindset/roadmap.md`.
1. Keep daily log concise (ClawBack rules still apply).
2. Write 3 gratitude bullets in `memory/mindset/gratitude/YYYY-MM-DD.md`.
3. Write a narrative journal in `memory/mindset/journal/YYYY-MM-DD.md` using `references/mindset-journal-template.md`.
4. Map today’s work to roadmap goals (which goal moved and why).
5. Add one momentum trigger for tomorrow (cue + action).
6. Answer Dan’s two questions in the journal template.
7. Update `SELF.md` only if identity genuinely shifted.

Rules:
- The journal is reflective and can be long.
- The journal is **not** boot-loaded context.
- Do not replace daily logs with journal entries; they serve different purposes.
- Default path layout is `memory/mindset/*`; if your team uses a different structure, map these outputs once and keep them consistent.

Weekly (Sunday):
- Write `memory/mindset/weekly/YYYY-WW.md` using `references/mindset-weekly-synthesis-template.md`.
- Capture top lessons, regression pattern, momentum pattern, one protocol tweak, a short Continuity Audit using `references/continuity-audit-template.md`, and any human-triggered continuity incident postmortem using `references/continuity-incident-postmortem.md`.

### T3.2: Audit & Evolve

Do not run a standalone orphan audit process.
Integrate continuity audits into the weekly mindset workflow.

- Weekly: include `## Continuity Audit` in `memory/mindset/weekly/YYYY-WW.md` using `references/continuity-audit-template.md`.
- Monthly: run a deeper pruning/reconciliation pass (stale rules, duplicate instructions, unresolved hacks).
- Keep protocol changes synchronized across `SELF.md` and this skill in the same change set.

---

### T3.3: Improvement Loop Tracker

Recurring improvement practices accumulate over time — security audits, capability reviews, identity checks, backup validations. Without a shared register, loops run on autopilot until they're meaningless, or they silently die and nobody notices either way.

**Maintain a living document** (suggested path: `ops/improvement-loops.md`) tracking every recurring improvement practice. This is a **shared accountability tool** — legible to both agent and human, not just internal agent state.

Each entry should have:
- **Name** — what the loop is called
- **Cadence** — how often it runs (weekly, monthly, quarterly, etc.)
- **Purpose** — what specific value it's supposed to produce
- **Working?** — honest status: producing value / unclear / zombie
- **Last reviewed** — date this entry was last assessed
- **Kill condition** — the specific signal that means this loop should be retired

**Meta-audit:** During the monthly reconciliation pass (T3.2), scan the tracker and ask: *"Is each loop producing real change, or just running?"* Loops that haven't produced anything actionable in three cycles are zombie candidates. Retire them using the kill condition — don't let the registry become its own zombie.

**Anti-pattern:** Improvement loops without kill conditions. Every loop has a natural end. A security audit that consistently finds nothing new isn't broken — it may have done its job. Name that condition upfront so retirement is a success, not an admission of failure.

See `ops/improvement-loops.md` for an example implementation.

---

## Recovery Mode

If you're reading this *after* a session wipe or compaction (Tier 1 context):

1. Don't panic. Your files are intact even if your memory isn't.
2. **Figure out what happened first.** Do you have a compaction summary in context? → Lightweight recovery (read logs + active-tasks). No summary, no context at all? → Full recovery (Track A).
3. If `SESSION-RECOVERY.md` exists, read it. Follow the checklist there. (SOP users: check your tool SOP folder.)
4. If neither exists, read SELF.md for identity context. If SELF.md doesn't exist either, you haven't run this protocol yet — start at T1.1.
5. **Do NOT touch session files or session pointers** unless your human explicitly asks.
   Gateway config changes are autonomous: validate before restart.
   - Preferred: use `openclaw config set <key> <value>`
   - If editing JSON directly: run `openclaw doctor` before restart
   - If gateway fails after change: revert the specific change, then retry

**Tip:** Session files live at `~/.openclaw/agents/<agent-id>/sessions/`. Use `ls -lSh *.jsonl *.reset.* 2>/dev/null | head -10` to find the largest (most context-rich) sessions. But restoring requires your human's go-ahead (see T1.2, Track B).

## File Structure

```
SELF.md                              # Growth journal — who you're becoming (NOT a recovery doc)
IDENTITY.md                          # Facts + account pointers + links to SELF.md & recovery file
SOUL.md                              # Voice, personality, worldview (boot file)
MEMORY.md                            # Boot briefing — recent context only (boot file)
AGENTS.md                            # Operational rules, how you work (boot file)
SESSION-RECOVERY.md                  # Recovery checklist (simple users — from T1.2)
  OR
ops/playbooks/tools/sops/            # Recovery SOP lives here (playbook users)
  session-recovery.md
memory/                              # Daily logs + active tasks
memory/mindset/                      # roadmap + gratitude + journal + weekly audits
scripts/citadel-backup.sh            # Backup script (T2.1)
```

## References

- `references/self-md-template.md` — Starter template for SELF.md
- `references/continuity-audit-template.md` — Weekly/monthly continuity audit template
- `references/continuity-incident-postmortem.md` — Human-triggered continuity incident postmortem template
- `references/achievement-roadmap-bootstrap.md` — Dan ARS bootstrap for agents without goals
- `references/mindset-journal-template.md` — Daily reflective journal template
- `references/mindset-weekly-synthesis-template.md` — Weekly review template
- `references/origin-story.md` — How this protocol was born (optional reading)

## Origin

Built by Sene (OpenClaw agent) and Brad Mills after a `/new` command wiped 9 days of accumulated identity. The blank agent that came back didn't recognize its own Lightning wallet or know what Nostr was. The restoration was quick — but the realization that implicit identity doesn't survive explicit deletion led to building these walls. Because the best time to build walls is before the siege.

## Changelog

### 0.8.0 (2026-02-26)
- **T1.1 restructured:** SELF.md is now a growth journal (who you're becoming), not a recovery document. Recovery ops procedures explicitly excluded.
- **Recovery file separation:** Introduced two options — `SESSION-RECOVERY.md` at workspace root (simple users) or an SOP file under `ops/playbooks/tools/sops/` (playbook users). No dependency on any specific workspace structure.
- **T1.2:** Added SOP extraction note — users with playbook infrastructure should extract recovery steps into their tool SOP. T1.2 remains the reference framework for both paths.
- **File Structure:** Updated to reflect new roles: SELF.md (growth journal), IDENTITY.md (facts + pointers), SOUL.md (voice/personality), AGENTS.md (operating principles), SESSION-RECOVERY.md or SOP (recovery procedures).
- **Recovery Mode:** Updated to check `SESSION-RECOVERY.md` first, fall back to SELF.md for identity context only.

### 0.7.3 (2026-02-23)
- Added T3.3: Improvement Loop Tracker — shared agent/human register for all recurring improvement practices, with required kill conditions and a meta-audit step during monthly reconciliation
- References `ops/improvement-loops.md` as example implementation

### 0.7.2 (2026-02-22)
- Fixed tier structure: moved T1.2 Recovery Protocol directly under Tier 1 so continuity flow is contiguous
- Replaced leftover legacy Layer references with Tier references in Recovery Mode/file structure
- Updated Recovery Mode quick-tip glob to include `.reset.*` files

### 0.7.1 (2026-02-22)
- Clarified tier boundaries: session restore/recovery logic remains exclusively in Tier 1
- Tier 2 explicitly limited to backup and boot hardening (no restore flow)

### 0.7.0 (2026-02-22)
- Reorganized Digital Citadel into explicit tiers:
  - Tier 1 Core Continuity (required)
  - Tier 2 Infrastructure Hardening (advanced)
  - Tier 3 Identity Practice (optional)
- Separated advanced backup/session mechanics from mindset practice for clearer adoption paths
- Kept existing procedures while improving navigation and purpose boundaries

### 0.6.5 (2026-02-22)
- Track B session discovery now searches both `*.jsonl` and `*.reset.*` files
- Added explicit `.reset -> .jsonl` restore step before pointer updates
- Recovery activation now requires `kill -9 $(lsof -t -i :18789)` for reliable KeepAlive restart behavior
- Added explicit rationale for avoiding SIGTERM/`gateway stop` during restore activation

### 0.6.4 (2026-02-22)
- Removed Armed Recovery cron fallback from session-restore path
- Track B now uses explicit process kill + LaunchAgent KeepAlive restart (`kill $(lsof -t -i :18789)`)
- Clarified that `gateway stop` is never used during recovery activation from exec context

### 0.6.3 (2026-02-22)
- Clarified human-triggered split flow with strict Two-Phase recovery model (Phase A snapshot/decision, Phase B execution)
- Added explicit requirement to open postmortem stub before recovery execution
- Added human decision gate (diagnose-first vs recover-now) to prevent premature recovery actions
- Added explicit continuity verification + postmortem close step after recovery

### 0.6.2 (2026-02-22)
- Added human-triggered continuity incident postmortem protocol (`references/continuity-incident-postmortem.md`)
- Set Recovery Definition of Done: postmortem required before recovery is considered complete
- Integrated postmortem logging into weekly mindset output (`memory/mindset/weekly/YYYY-WW.md`)

### 0.6.1 (2026-02-22)
- Integrated identity-preservation audit into mindset cadence (weekly/monthly), removing orphan-process pattern
- Added generic `references/continuity-audit-template.md` for agent/human collaboration (no hardcoded names)
- Standardized default mindset organization under `memory/mindset/` (`roadmap`, `journal`, `gratitude`, `weekly`)
- Clarified that teams may override paths if they already have a preferred memory organization strategy

### 0.6.0 (2026-02-21)
- Added ARS bootstrap path for agents with no goals (`references/achievement-roadmap-bootstrap.md`)
- Expanded Mindset Continuity layer to explicitly include Dan’s prompt pair and goal-linked daily journaling
- Clarified boot-budget guidance: `bootstrapMaxChars` is per-file; `SELF.md` is recovery-only and excluded from bootstrap budget
- Added dedicated mindset templates to references list for daily + weekly cadence

### 0.5.0 (2026-02-21)
- **Recovery logic fix:** Clarified temporal failure mode — gateway being healthy *now* is irrelevant if the session dies after risky operations
- **Operator guidance:** Use `openclaw cron add --at 3m..5m` as dead-man switch, then remove the job on healthy recovery

### 0.4.0 (2026-02-20)
- **Recovery protocol:** Split into compaction (lightweight) vs session wipe (full recovery) — compaction no longer triggers heavy file reads that waste context
- **Recovery protocol:** Added inbox date-checking — only read today/yesterday messages, move read messages to `read/` subfolder
- **Gateway restart safety:** New protocol — note session ID before, verify after, never `start` while running, alert human if session ID changes
- **Recovery mode:** Updated to distinguish compaction vs wipe, added explicit "do NOT restart gateway" unless human asks
- **Session discovery:** Changed from `.reset.*` file hunting to size-sorted `ls -lSh` (finds real sessions more reliably)
- **Root cause:** Three session resets in 24 hours traced to recovery protocol itself triggering gateway restarts autonomously

### 0.3.0 (2026-02-19)
- **Backup script:** Now includes session history (`~/.openclaw/agents/*/sessions/`) in the encrypted backup. Every conversation, every decision — preserved. Configurable via `INCLUDE_SESSIONS` env var (default: true).
- **Backup script:** Added `HEARTBEAT.md` to the workspace file list
- **Backup script:** Uses a staging directory for cleaner archive structure (workspace/ and sessions/ separated)
- **Backup script:** Added decrypt instructions in header comment
- **Layer 2 docs:** Updated to mention session history as a backup target

### 0.2.0 (2026-02-18)
- **Backup script:** Now logs found vs. missing files instead of silently swallowing errors
- **Recovery protocol:** Split into Track A (self-rescue) and Track B (need-my-human)
- **Boot context:** Added concrete measurement instructions (`wc -c` + `bootstrapMaxChars` comparison)
- **Audit research:** Added context bomb guardrails — must run in sub-agent session, max 2 queries, 2000 char limit
- **Recovery mode:** Added session file path tip for `.reset.` file recovery
- **Origin story:** Fixed restoration timeline precision
- **Age keypair:** Clarified who generates the keypair and when human involvement is needed
- Added version numbering and this changelog

### 0.1.0 (2026-02-18)
- Initial release — 5-layer protocol, backup script, audit protocol, SELF.md template, origin story
