# Architecture

## Data model

One Markdown file per wisdom snippet. Storage path:
`wisdoms/<YYYY>/<MM>/<ulid>.md`.

Frontmatter (YAML) carries all metadata; body below the fence is the snippet
itself in Markdown. Schema enforced by the capture skill and verified by the
site build.

| Field | Type | Notes |
|-------|------|-------|
| `id` | string (ulid) | 26-char lowercase Crockford base32; matches filename |
| `created_at` | string (ISO-8601 UTC) | second precision |
| `updated_at` | string (ISO-8601 UTC) | present only after edit |
| `body_hash` | string (sha256 hex) | of normalized body |
| `category` | string | one of keys in `wisdoms/_categories.yml` |
| `tags` | array of strings | lowercase, hyphenated |
| `source_url` | string \| null | original URL where wisdom was found |
| `source_author` | string \| null | named source / handle |
| `note` | string | user's personal gloss; may be empty |
| `import_origin` | string \| null | one of `manual`, `file:<basename>`, `url:<url>`, `notion:<basename>` |

## Components

```
bin/wisdom              # thin zsh dispatcher
└── lib/
    ├── _shared.zsh     # ulid, hash, repo path, length guard, dedup
    ├── _import_helpers.zsh   # wisdom_write_record
    ├── _url_helpers.zsh      # url_hash, url_cache_dir, url_domain
    └── cmd_*.zsh       # one module per subcommand

.claude/skills/wisdom-capture/   # installed per-project via:
└── SKILL.md                     #   npx skills@latest add amit-t/skills --skill wisdom-capture
                                 # canonical source: github.com/amit-t/skills/tree/main/wisdom-capture
                                 # 11-step categorize→write→commit→push flow

wisdoms/
├── _categories.yml     # closed taxonomy + color_pool
└── YYYY/MM/<ulid>.md   # the corpus

_layouts/, _includes/, _plugins/, assets/, etc.  # Jekyll site

.cache/imports/<sha256-of-url>/  # ephemeral; gitignored
├── meta.json (yt-dlp metadata)
├── audio.{mp3,m4a,wav}
├── transcript.txt (Whisper)
├── thumb.{jpg,png,webp}
├── keyframes/frame-NNN.jpg
├── caption.txt / page-text.txt / comments.txt (Playwright)
├── manual-paste.txt (manual fallback)
├── agent-directive.md (Playwright handoff)
└── prompt.txt (final preview bundle handed to agent)
```

## Capture flow

```
wisdom "text"                          terminal
   │
   ├── parse args → snippet?
   ├── length guard (≥20 chars)
   ├── launch claude / codex / devin   engine
   │     └── /wisdom or auto-trigger from AGENTS.md
   │           └── SKILL.md (11 steps)
   │                 ├── propose category + tags
   │                 ├── confirm with user
   │                 ├── compute id, hash, paths
   │                 ├── write wisdoms/YYYY/MM/<id>.md
   │                 ├── git add + commit
   │                 └── prompt push?
   └── exit
```

## URL ingest pipeline

```
wisdom import-url <url> [<url>…]
   │
   ├── parallel scrape (per URL):
   │     ├── yt-dlp → meta.json, audio.*, thumb.*
   │     ├── if fail → write Playwright directive in agent-directive.md
   │     ├── ffmpeg keyframes (if video)
   │     ├── Whisper transcribe (if audio)
   │     └── comments (yt-dlp or Playwright)
   │
   └── sequential extract (per URL):
         ├── re-import dedup check (skip / view / update / new)
         ├── assemble prompt.txt = caption + transcript + comments + image refs
         └── launch engine with prompt + cache paths
               └── SKILL.md URL-handoff branch
                     ├── vision: read keyframes / cover
                     ├── synthesize candidate body
                     ├── confirm with user
                     └── normal write/commit/push flow
```

## Site build

```
push to main
   │
   └── .github/workflows/pages.yml
         ├── bundle exec jekyll build
         │     ├── _config.yml: collection _wisdoms, permalink /w/:id/
         │     ├── _layouts/wisdom.html renders permalinks with Pagefind attrs
         │     ├── buckets/*.md filter collection by category
         │     ├── _plugins/tag_pages.rb generates /tags/<tag>/
         │     └── output → _site/
         ├── npx pagefind --site _site
         │     └── crawls _site, builds /pagefind/<index>.{js,wasm}
         └── deploy-pages → https://<owner>.github.io/wisdom/
```

## External tool dependencies

All optional except `git`. Each tool's absence produces a graceful skip or
actionable error.

| Tool | Used by | Install (macOS) |
|------|---------|-----------------|
| `git` | every commit | comes with Xcode CLT |
| `jq` | json import, comments parsing | `brew install jq` |
| `python3` | csv import | `brew install python` |
| `unzip` | notion import | system |
| `ripgrep` (rg) | find | `brew install ripgrep` (falls back to grep) |
| `yt-dlp` | URL import L1 | `brew install yt-dlp` |
| `ffmpeg` | keyframes | `brew install ffmpeg` |
| `whisper-cpp` | transcription (local) | `brew install whisper-cpp` |
| Playwright MCP | URL import L2 | `docs/playwright-mcp-setup.md` |
| `claude` / `codex` / `devin` | capture session | per-vendor |

## Trade-offs + non-goals

- **No backend.** Pagefind is a static index; no API server. Cost: search
  index rebuilds on every push (~seconds for thousands of entries).
- **Closed taxonomy.** Buckets are intentionally limited. New buckets land
  only via the skill's explicit "propose new bucket" path, gated on user
  confirmation.
- **One commit per snippet.** Chosen for blame + revertability. Cost:
  high commit volume in active capture sessions.
- **Vision-LLM in place of OCR.** Image-trapped wisdom (slide-style reels,
  quote cards) is read by the engine directly. Cost: API tokens per image.
  Benefit: no Tesseract install, better extraction quality.
- **No real-time sync.** Snippets land on local main first; push is opt-in
  per session. Multi-device capture requires manual `git pull`.
