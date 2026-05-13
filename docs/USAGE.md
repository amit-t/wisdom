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

## Admin subcommands

### ls

```bash
wisdom ls                          # 20 most recent
wisdom ls --bucket engineering     # filter by bucket
wisdom ls --limit 100              # show more
```

Output columns: `<id-prefix>  <date>  [<bucket>]  <body preview>`.

### show

```bash
wisdom show 01jx8z                 # by id-prefix
wisdom show 01jx8zk2m9p3qrstvwxyz  # full id
```

Prefix must resolve uniquely. If it matches multiple, the candidates are
listed and the command exits 1.

### find

```bash
wisdom find "rich hickey"          # case-insensitive substring
wisdom find optimization
```

Searches body, frontmatter, and notes via ripgrep (falls back to grep).
Output: `<id>  [<bucket>]  <matching line>`.

### edit

```bash
wisdom edit 01jx8z                 # opens $EDITOR
wisdom edit 01jx8z --no-recat      # default behavior (skips skill recat)
```

After save, `body_hash` and `updated_at` are recomputed automatically and a
new commit is made:

```
wisdom: edit 01jx8z — <body first 60>…
```

### rm

```bash
wisdom rm 01jx8z                   # interactive confirm
wisdom rm --yes 01jx8z             # skip confirm
```

`git rm` the file and commit:

```
wisdom: remove 01jx8z — <body first 60>…
```

## Imports

### Files

```bash
wisdom import path/to/file.md             # auto-detect format
wisdom import --format json export.json
wisdom import --format csv export.csv
wisdom import --format txt notes.txt
wisdom import --format notion-export export.zip
wisdom import --dry-run file.md           # preview, no writes
wisdom import --no-categorize file.md     # skip skill (default category: life)
```

| Format | Detection | Notes |
|--------|-----------|-------|
| `md` | `.md`, `.markdown` | Split on `\n---\n`. Each chunk = one wisdom. |
| `json` | `.json` | Array of objects: `body`, `source_url`, `source_author`, `note`, `category`, `tags[]`. |
| `csv` | `.csv` | Header row required: `body,source_url,source_author,note,category,tags`. Tags are pipe-separated within the column. |
| `txt` | `.txt` | Split on blank-line-separated paragraphs. |
| `notion-export` | `.zip` | Unzips, treats each `.md` as one wisdom (H1 line stripped). |

One commit per import: `wisdom: import N entries from <basename>`.

### URLs

```bash
wisdom import-url https://www.instagram.com/reel/...
wisdom import-url <url1> <url2> <url3>    # batch (parallel scrape, sequential extract)
wisdom import-url --engine codex <url>
```

Pipeline per URL:

1. **yt-dlp** — metadata, audio, thumbnail. Public IG / X / YT / TikTok /
   Vimeo.
2. **Playwright MCP fallback** — if yt-dlp fails, the agent uses its
   registered Playwright MCP (if any) to scrape from your logged-in browser.
   See `docs/playwright-mcp-setup.md`.
3. **Manual paste** — if both above fail, the URL opens in your browser and
   you paste content directly.

Side helpers:
- **ffmpeg** extracts up to 12 keyframes (one per 5s) for slide-style reels.
- **Whisper** transcribes audio if present (`WISDOM_WHISPER=local|api`).
- **Comments** (Instagram only): top 5 by like count via yt-dlp or
  Playwright.

The agent's job is **extraction**, not transcription: it reads the keyframes
(vision-capable), picks the strongest sentence from the transcript, and
proposes a candidate `body`. You confirm or edit.

### Re-import handling

If the URL was already imported, you see:

```
URL already imported as 01jx8z:
  <body preview>
[v]iew / [u]pdate-note / [n]ew-extract / [c]ancel (default: c):
```

Non-interactive: `WISDOM_REIMPORT_DEFAULT=skip|new|cancel`.
