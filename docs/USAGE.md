# Usage

## Capture (Phase 1)

### Quick capture

```bash
# Positional
wisdom "Make it work, make it right, make it fast. — Kent Beck"

# Stdin
pbpaste | wisdom -

# Editor
wisdom -e

# Pure launcher (paste inside chat)
wisdom
```

### Engine selection

```bash
wisdom --engine codex "snippet"
WISDOM_ENGINE=devin wisdom "snippet"
```

### Inside an agent session

Type the trigger and paste:

- Claude Code: `/wisdom`
- Devin: `/wisdom`
- Codex: `$wisdom`

### Environment

| Var | Default | Purpose |
|-----|---------|---------|
| `WISDOM_REPO` | `~/Projects/AmitTiwari/wisdom` | repo path |
| `WISDOM_ENGINE` | `claude` | `claude` \| `codex` \| `devin` |
| `WISDOM_EDITOR` | `$EDITOR` | overrides editor for `-e` and `edit` |
| `WISDOM_WHISPER` | `local` | `local` (whisper.cpp) \| `api` (OpenAI Whisper) |
| `WISDOM_NO_PUSH` | unset | skip push prompts when set |

### Exit codes

| Code | Meaning |
|------|---------|
| 0 | success |
| 1 | user error |
| 2 | repo not found |
| 3 | engine launch failure |
| 4 | git conflict aborted |
| 5 | dedup cancelled |
| 6 | length guard rejected |
| 7 | scrape pipeline failed (URL import) |

## Site (Phase 2)

(Filled in during Phase 2.)

## Admin subcommands (Phase 3)

(Filled in during Phase 3.)

## Imports (Phase 3)

(Filled in during Phase 3.)
