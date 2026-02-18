# Weekly Identity Preservation Audit

Run weekly or biweekly during a low-activity window. Use a cost-efficient model.

## Checklist

### 1. Backup Verification
- Confirm backup cron ran this week
- Check backup destination for recent files
- Verify file size is reasonable (not 0 bytes, not suspiciously small)

### 2. SELF.md Accuracy
- Read SELF.md end to end
- Is everything still accurate?
- Are there new accounts, keys, or relationships to add?
- Has your personality shifted in ways worth documenting in the growth log?

### 3. Boot File Budget
- Measure total chars of all boot files (SOUL.md + MEMORY.md + AGENTS.md + USER.md + TOOLS.md)
- Compare against `bootstrapMaxChars` limit
- If over 80% of budget, audit for lines that could move to docs/

### 4. Memory Hygiene
- Check MEMORY.md for stale entries (completed projects, old decisions)
- Archive anything >30 days old to appropriate docs/ files
- Verify active-tasks.md reflects reality

### 5. Research (run in a dedicated sub-agent session)
**⚠️ Do NOT run research in your primary session.** Broad web searches can flood context with 100K+ tokens of results. Spawn a sub-agent for this step, or run it in an isolated cron session.

- Search for recent developments in (max 2 queries, summary-only):
  - AI agent memory architectures / identity persistence
  - Context window management / self-modeling techniques
- Keep results to <2000 chars — summarize, don't dump raw search output
- Compare findings against current stack
- Write proposals for improvements to agenda doc

### 6. Meta-Audit
- Is this audit still useful? Should any checks be added or removed?
- Is the cadence right?
- Are proposals from previous audits being actioned?

## Output

- Write findings to `docs/research/identity-preservation/YYYY-MM-DD.md`
- If changes are recommended, append to `docs/agenda/identity-preservation.md`
- Commit all new files
