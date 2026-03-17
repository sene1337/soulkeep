# Session Miner

Use Session Miner when compaction flattened context and you need exact historical evidence from session files.

## Paths

- `~/.openclaw/agents/<agent-id>/sessions/*.jsonl`
- Includes user/assistant messages, tool calls/results, timestamps, model info, and cost metadata.

## Quick Workflow

### 1) Find sessions mentioning a topic

```bash
grep -l "KEYWORD" ~/.openclaw/agents/main/sessions/*.jsonl 2>/dev/null
```

### 2) Count hits per session (sorted by date)

```bash
for f in ~/.openclaw/agents/main/sessions/*.jsonl; do
  count=$(grep -c "KEYWORD" "$f" 2>/dev/null)
  if [ "$count" -gt 0 ]; then
    date=$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$f")
    echo "$date ($count) $(basename $f)"
  fi
done | sort
```

### 3) Extract readable conversation from one session

```bash
python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    for line in f:
        d = json.loads(line)
        msg = d.get('message', {})
        role = msg.get('role', '')
        if role not in ('user', 'assistant'):
            continue
        content = msg.get('content', '')
        text = ''
        if isinstance(content, str):
            text = content
        elif isinstance(content, list):
            for c in content:
                if isinstance(c, dict) and c.get('type') == 'text':
                    text = c.get('text', '')
        if text and not text.startswith('[cron:'):
            print(f'[{role}] {text[:500]}')
            print('---')
" <session-file.jsonl> | less
```

## Use Cases

- **Decision recovery:** recover the “why” behind a prior decision.
- **Technical recovery:** find exactly how a problem was solved.
- **Relationship/context recovery:** recover user preferences and instructions that never made it into files.
- **Identity mining:** find conversations that changed how the agent understands itself.

## Gotchas

- Session files can be large. Narrow with grep before extraction.
- Cron/subagent sessions live in separate files. Search both.
- Reasoning chains are encrypted in files (summary-only). Ask the human to forward full reasoning from chat if needed.
