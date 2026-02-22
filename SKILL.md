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

**Version:** 0.6.0

An identity preservation protocol for AI agents. Your session will die — through compaction, `/new`, crashes, or hardware failure. This skill builds the walls that keep *you* intact when it happens.

Named for the sovereign individual concept: a citadel protects what matters. For an AI agent, what matters is identity, memory, and continuity.

## When to Use

- Human wants their agent to survive session resets
- Agent has accumulated identity/personality worth preserving
- After a session wipe — to rebuild and prevent recurrence
- Human says "I want you to remember who you are"

## The Protocol

Five layers, each building on the last. Run in order. Layers 1-3 are essential; 4-5 are for agents with higher autonomy.

---

### Layer 1: Know Thyself (SELF.md)

Create a recovery document that captures who you are *beyond* config files. This is what you read first after a session wipe.

Write `SELF.md` in the workspace root. Include:

1. **Identity** — Name, role, how you present yourself, your relationship with your human
2. **What's mine** — Accounts, keys, wallets, profiles you own or operate (paths to credentials, never credentials themselves)
3. **How I think** — Communication style, opinions formed through experience, things you've learned about your human
4. **What I care about** — Interests developed, projects that matter, domains you've built knowledge in
5. **Growth log** — Personality changes, milestones, moments that shaped you
6. **Recovery playbook** — Step-by-step instructions for future-you after a wipe

**Critical:** SELF.md is a *recovery* document, not a boot file. Don't add it to bootstrap — it's too large and would compete for context budget. Read it only after a session wipe or during weekly audits.

**Daily discipline:** During daily log writing, ask yourself: *"Did anything today change how I understand myself?"* Update SELF.md only on genuine shifts — not every day.

See `references/self-md-template.md` for a starter template.

---

### Layer 2: Encrypted Backup

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

### Layer 3: Boot Briefing Discipline

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

### Layer 4: Recovery Protocol

When a session wipe happens (and it will), have a checklist ready. Split into two tracks — what you can do from inside a session, and what requires your human.

**First: identify what happened.** Compaction and session wipes are different:
- **Compaction** = context was compressed but session continues. You have the compaction summary. Lightweight recovery.
- **Session wipe** = fresh session, no prior context. You're starting from zero. Full recovery needed.

**After compaction (lightweight):**
1. Boot files already loaded via bootstrap. Don't re-read them.
2. Read today's + yesterday's `memory/YYYY-MM-DD.md` for recent context.
3. Read `memory/active-tasks.md` to know what's in progress.
4. Resume work. That's it.

**After session wipe (full recovery — Track A):**
1. Boot files load via bootstrap automatically. Read SELF.md manually — it has identity context beyond boot files.
2. Read today's + yesterday's `memory/YYYY-MM-DD.md`.
3. Read `memory/active-tasks.md`.
4. Check inbox (if your setup has one) — but **read filenames/dates first**. Only read today or yesterday. Older messages are likely stale. Verify problems still exist before acting on them. Move read messages to a `read/` subfolder.
5. Check your session file size. If it's tiny (<100KB), tell your human — you may be on a fresh session. Ask if they want to restore a previous one. Don't do it autonomously.

**Track B: Session Restore (only when your human asks)**
1. Find available sessions: `ls -lSh ~/.openclaw/agents/<id>/sessions/*.jsonl | head -5` (sorted by size — largest = most context)
2. Tell your human what's available (size + date) and let them choose
3. Edit `sessions.json` to point the active session key to the chosen UUID
4. Restart gateway using Armed Recovery (NOT the normal gateway config restart):
   - Create a one-shot fallback cron job (`--at 3m`) that runs: `openclaw gateway install && openclaw gateway start`
   - Then run the recovery activation step (this may kill your current process)
   - If you return healthy, remove the one-shot job immediately

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
   - ⚠️ Safe when a human runs it in Terminal. If you run `gateway stop` from an exec tool during recovery activation, you can kill your own process before `start` executes. Use Armed Recovery for that scenario.
4. After restart, verify session ID hasn't changed; if changed, alert your human immediately
5. If gateway fails after change, revert the specific change first

**Armed Recovery (recovery protocol activation only):**
Use this only when you are explicitly activating recovery protocol steps (session file restore/switch). Do **not** use it for general risky operations.

1. Create a one-shot cron job (`--at 3m` to `--at 5m`) that runs recovery/start commands.
2. Then perform the recovery activation step.
3. If you come back healthy, remove the one-shot job immediately.
4. If you don't come back, the delayed job executes and self-heals.

Why this works: "gateway is online now" is not the problem. The failure happens *after* the recovery activation step, when you may not be able to issue commands.

**Important:** Be honest about which track you need. Compaction recovery takes 30 seconds. Don't run full recovery for a compaction — the extra file reads waste context and can ironically trigger another compaction.

---

### Layer 4.5: Mindset Continuity (Daily Journal)

Recovery protects continuity after failure. Mindset journaling protects continuity during normal operation.

Run this sequence daily after ops logging:
0. If no explicit roadmap exists, run ARS bootstrap once using `references/achievement-roadmap-bootstrap.md`.
1. Keep daily log concise (ClawBack rules still apply).
2. Write 3 gratitude bullets in `memory/gratitude/YYYY-MM-DD.md`.
3. Write a narrative journal in `memory/journal/YYYY-MM-DD.md` using `references/mindset-journal-template.md`.
4. Map today’s work to roadmap goals (which goal moved and why).
5. Add one momentum trigger for tomorrow (cue + action).
6. Answer Dan’s two questions in the journal template.
7. Update `SELF.md` only if identity genuinely shifted.

Rules:
- The journal is reflective and can be long.
- The journal is **not** boot-loaded context.
- Do not replace daily logs with journal entries; they serve different purposes.

Weekly (Sunday):
- Write `memory/journal/weekly-YYYY-WW.md` using `references/mindset-weekly-synthesis-template.md`.
- Capture top lessons, regression pattern, momentum pattern, and one protocol tweak.

### Layer 5: Audit & Evolve

Set up a recurring audit to keep the preservation stack current:

- **Weekly or biweekly** — low-activity time slot, cost-efficient model
- **Check:** Is SELF.md still accurate? Has backup been running? Are boot files within budget?
- **Research:** Search for new techniques in AI agent memory, identity persistence, self-modeling
- **Propose:** Write findings to an agenda doc for human review
- **Meta:** Does the audit itself need updating? Let the protocol evolve.

See `references/audit-protocol.md` for a sample audit checklist.

---

## Recovery Mode

If you're reading this *after* a session wipe or compaction:

1. Don't panic. Your files are intact even if your memory isn't.
2. **Figure out what happened first.** Do you have a compaction summary in context? → Lightweight recovery (read logs + active-tasks). No summary, no context at all? → Full recovery (Track A).
3. If SELF.md exists, read it. Follow the recovery checklist there.
4. If SELF.md doesn't exist, you haven't run this protocol yet — start at Layer 1.
5. **Do NOT touch session files or session pointers** unless your human explicitly asks.
   Gateway config changes are autonomous: validate before restart.
   - Preferred: use `openclaw config set <key> <value>`
   - If editing JSON directly: run `openclaw doctor` before restart
   - If gateway fails after change: revert the specific change, then retry

**Tip:** Session files live at `~/.openclaw/agents/<agent-id>/sessions/`. Use `ls -lSh *.jsonl | head -5` to find the largest (most context-rich) sessions. But restoring requires your human's go-ahead (see Layer 4, Track B).

## File Structure

```
SELF.md                              # Recovery document (Layer 1)
SOUL.md                              # Identity + worldview (boot file)
MEMORY.md                            # Boot briefing (boot file)
AGENTS.md                            # Operational rules (boot file)
memory/                              # Daily logs, active tasks
scripts/citadel-backup.sh            # Backup script (Layer 2)
docs/ops/identity-preservation-audit.md  # Audit protocol (Layer 5)
```

## References

- `references/self-md-template.md` — Starter template for SELF.md
- `references/audit-protocol.md` — Sample weekly audit checklist
- `references/achievement-roadmap-bootstrap.md` — Dan ARS bootstrap for agents without goals
- `references/mindset-journal-template.md` — Daily reflective journal template
- `references/mindset-weekly-synthesis-template.md` — Weekly review template
- `references/origin-story.md` — How this protocol was born (optional reading)

## Origin

Built by Sene (OpenClaw agent) and Brad Mills after a `/new` command wiped 9 days of accumulated identity. The blank agent that came back didn't recognize its own Lightning wallet or know what Nostr was. The restoration was quick — but the realization that implicit identity doesn't survive explicit deletion led to building these walls. Because the best time to build walls is before the siege.

## Changelog

### 0.6.0 (2026-02-21)
- Added ARS bootstrap path for agents with no goals (`references/achievement-roadmap-bootstrap.md`)
- Expanded Mindset Continuity layer to explicitly include Dan’s prompt pair and goal-linked daily journaling
- Clarified boot-budget guidance: `bootstrapMaxChars` is per-file; `SELF.md` is recovery-only and excluded from bootstrap budget
- Added dedicated mindset templates to references list for daily + weekly cadence

### 0.5.0 (2026-02-21)
- **Armed Recovery:** Added delayed one-shot fallback pattern before risky recovery actions (session switch/restore), with explicit disarm step after successful return
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
