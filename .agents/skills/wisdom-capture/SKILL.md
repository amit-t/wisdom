---
name: wisdom-capture
description: Use when the user wants to record a wisdom snippet — short or long quote, idea, or observation worth keeping. Captures from terminal CLI (`wisdom`) or in-session slash command (`/wisdom` / `$wisdom`). Categorizes into a closed bucket from wisdoms/_categories.yml, writes a frontmatter Markdown file, and commits.
---

# Wisdom Capture

## Overview

You are recording a snippet of wisdom into the user's personal corpus. The
corpus lives at `$WISDOM_REPO` (default `~/Projects/AmitTiwari/wisdom`). Each
snippet becomes one Markdown file under `wisdoms/<YYYY>/<MM>/<ulid>.md` with
strict frontmatter, then one git commit.

You MUST follow the 11-step flow below in order. Do not skip steps. Do not
improvise the schema. If you cannot proceed for any reason, surface the
problem to the user explicitly — do not silently save partial data.

## Inputs

You receive the snippet via one of:
- A first user-turn message containing `Record this wisdom snippet: <body>`
- An interactive prompt where the user types `/wisdom` (Claude/Devin) or
  `$wisdom` (Codex) and then pastes the snippet
- Inside the URL-import flow (Phase 3), a pre-assembled preview with caption,
  transcript, and images

You MUST `cd` into the repo before any git operation:
`cd "$WISDOM_REPO"` (or the value from `wisdom_repo_path`).

## The 11-step flow

### Step 1 — Detect inputs

If the first turn already has a snippet, use it. Otherwise ask:
"Paste your wisdom snippet."

### Step 2 — Enrich (best-effort)

If the snippet contains a URL, attempt to fetch the page title and author
using your available web tools. Skip on failure. Ask the user explicitly for
`source_url` and `source_author` only if neither is derivable.

### Step 3 — Strip / clean

Trim leading and trailing whitespace. Preserve internal Markdown formatting.
Do NOT auto-rewrite the snippet's prose.

### Step 4 — Propose category + tags

Read `wisdoms/_categories.yml`. Decide:

- **Primary bucket** — exactly one key from the file
- **Confidence** — `high` | `med` | `low`
- **Tags** — 2–5 lowercase hyphenated strings
- **If no bucket fits** — propose a new bucket with `key`, `label`, `color`
  (pick from `color_pool`), and a one-sentence reason. ALSO provide
  `second_best` — the closest existing bucket.

### Step 5 — Confirm with user

Show the proposal as a compact table. Options: `[y] accept`, `[n] reject`,
`[edit] adjust tags/note inline`.

### Step 6 — Ask for personal note (optional)

"Want to add your own gloss? (enter to skip)"

### Step 7 — Write file

- Compute `id = ulid` (lowercase 26-char Crockford base32)
- Compute `body_hash = sha256(normalize(body))`
- Set `created_at = now in ISO 8601 UTC`
- Choose path `wisdoms/<YYYY>/<MM>/<id>.md`
- Render frontmatter exactly per the schema in master plan §C2.

### Step 8 — Update index

(Removed — Pagefind crawls built HTML at build time, no manual index.)

### Step 9 — Commit

```bash
git status --porcelain
git add wisdoms/<YYYY>/<MM>/<id>.md
git commit -m "wisdom: <category> — <body first 60 chars>…

source: <url if present>
tags: <comma list>"
```

### Step 10 — Push (per session)

Read `.wisdom-session` if present. Honor `always` / `never`. Otherwise prompt.
Persist choice to `.wisdom-session` (gitignored).

### Step 11 — Report + loop

Print file path, category + tags, commit sha, Pages URL if push happened.

## Edge cases

### Dedup hit

Before Step 7, check `wisdom_find_dup "$body" "$WISDOM_REPO"`. If non-empty,
prompt the user with skip/add/merge/cancel options.

### Length guard

Body length < 20 chars → reject. Length > 5000 → warn but continue.

### Vision (Phase 3 URL import context)

If images are attached to the session, read them. Extract text content. Treat
the extracted text as additional context for the snippet body (do not replace
the user's curated body; offer it as a candidate during Step 5).

### No-categories.yml

If `wisdoms/_categories.yml` is missing or unparseable, halt with error. Do
not invent buckets.

## Verification before declaring done

- File written under `wisdoms/<YYYY>/<MM>/<id>.md`
- Frontmatter parses as valid YAML
- `id` matches filename
- `body_hash` matches `sha256(normalize(body))`
- Commit landed on local `main`

See REFERENCE.md for prompt templates and the full JSON output schema.
