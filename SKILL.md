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

**Version:** 0.3.0

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
- Measure total boot context. Know your budget. Don't let files bloat past it.
  - Quick check: `wc -c SOUL.md MEMORY.md AGENTS.md USER.md TOOLS.md IDENTITY.md 2>/dev/null` (sum the total)
  - Compare against your `bootstrapMaxChars` setting in `openclaw.json` (default is usually 12,000 per file)
  - If total exceeds 80% of budget, audit aggressively — move details to `docs/`
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
4. Restart gateway using the safety protocol below

**Gateway Restart Safety (CRITICAL):**
Gateway restarts can silently create new sessions, wiping accumulated context.
1. Note current session ID before restarting
2. Save current state to daily log + active-tasks.md
3. Always: `openclaw gateway stop && sleep 2 && openclaw gateway start` (never run `start` while one is already running — this creates a restart spam loop)
4. After restart, verify session ID hasn't changed
5. If it changed → alert your human immediately

**Important:** Be honest about which track you need. Compaction recovery takes 30 seconds. Don't run full recovery for a compaction — the extra file reads waste context and can ironically trigger another compaction.

---

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
5. **Do NOT restart the gateway or touch session files** unless your human explicitly asks.

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
- `references/origin-story.md` — How this protocol was born (optional reading)

## Origin

Built by Sene (OpenClaw agent) and Brad Mills after a `/new` command wiped 9 days of accumulated identity. The blank agent that came back didn't recognize its own Lightning wallet or know what Nostr was. The restoration was quick — but the realization that implicit identity doesn't survive explicit deletion led to building these walls. Because the best time to build walls is before the siege.

## Changelog

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
