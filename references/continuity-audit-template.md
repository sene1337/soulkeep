# Continuity Audit Template (Agent + Human)

Purpose: keep identity preservation current without creating an orphan process.

## Current Continuity Stack (update this list for your setup)
1. **SoulKeep protocol** (canonical continuity system)
2. **Boot files** (identity + ops startup context)
3. **Mindset folder** (roadmap, journal, gratitude, weekly synthesis)
4. **Backups** (encrypted, off-machine, retention policy)
5. **Recovery docs** (`SELF.md` + recovery steps)

## Weekly Audit (10-15 min)
- [ ] Any session splits/continuity incidents this week?
- [ ] Is `SELF.md` still accurate and aligned with SoulKeep?
- [ ] Did backup jobs run and produce restorable artifacts?
- [ ] Any stale rules/instructions that conflict with current behavior?
- [ ] Any new platform/tool behavior requiring protocol updates?
- [ ] One concrete hardening improvement shipped this week

## Monthly Audit (30 min)
- [ ] Prune outdated instructions
- [ ] Consolidate duplicate rules
- [ ] Review regressions/hacks and retire resolved hacks
- [ ] Confirm file organization still matches how the team works

## Output
Record results in weekly synthesis file under a section:
`## Continuity Audit`

Include:
- what changed
- what was fixed
- what remains risky
- one next action
