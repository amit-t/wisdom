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

Internal reasoning template:

```json
{
  "primary": "engineering",
  "confidence": "high",
  "tags": ["debugging", "systems"],
  "reason": "Quote is about programming practice.",
  "new_bucket_proposal": null,
  "second_best": "craft"
}
```

### Step 5 — Confirm with user

Show the proposal as a compact table:

```
category: engineering   (confidence: high)
tags:     debugging, systems
source:   https://...
author:   Rich Hickey
```

Options: `[y] accept`, `[n] reject`, `[edit] adjust tags/note inline`.

On reject:
- If you proposed a new bucket: ask the user; if they reject the new bucket,
  switch to `second_best` and confirm again.
- If no new bucket: ask which existing bucket they want.

### Step 6 — Ask for personal note (optional)

"Want to add your own gloss? (enter to skip)"

### Step 7 — Write file

- Compute `id = ulid` (lowercase 26-char Crockford base32)
- Compute `body_hash = sha256(normalize(body))`
- Set `created_at = now in ISO 8601 UTC`
- Choose path `wisdoms/<YYYY>/<MM>/<id>.md`
- Render frontmatter exactly per the schema in master plan §C2. Tags as a
  YAML array; nullable string fields rendered as `null` not `~`.

### Step 8 — Update index

(Removed — Pagefind crawls built HTML at build time, no manual index.)

### Step 9 — Commit

```bash
git status --porcelain        # MUST be clean except for our new file
git add wisdoms/<YYYY>/<MM>/<id>.md
git commit -m "wisdom: <category> — <body first 60 chars>…

source: <url if present>
tags: <comma list>"
```

If `git status` shows other dirty files, ask: `[s]tash / [a]bort / [c]ommit-mine-only`.

### Step 10 — Push (per session)

Read `.wisdom-session` if present. Honor `always` / `never`. Otherwise prompt:
`push now? [y/n/always/never]`. Persist choice to `.wisdom-session` (gitignored).

Before push, `git pull --rebase --autostash origin main`. If conflict: bail
out (exit 4 equivalent — print error, do not auto-resolve). The committed file
is already safe in local main.

If `WISDOM_NO_PUSH` env is set, skip prompting entirely.

### Step 11 — Report + loop

Print:
- File path
- Category + tags
- Commit sha (short)
- Pages URL if push happened: `https://<owner>.github.io/wisdom/w/<id>/`

Then ask: "another snippet? paste below or type `done`."

## Edge cases

### Dedup hit

Before Step 7, check `wisdom_find_dup "$body" "$WISDOM_REPO"`. If non-empty:

```
This snippet already exists as wisdom <id>:
  category: <existing.category>
  body: <first 80 chars>

[s]kip this capture
[a]dd anyway (rare; e.g., same quote different attribution)
[m]erge note into existing
[c]ancel
```

### Length guard

Body length < 20 chars → reject with "snippet too short". Length > 5000 → warn
but continue.

### Vision (Phase 3 URL import context)

If images are attached to the session, read them. Extract text content. Treat
the extracted text as additional context for the snippet body (do not replace
the user's curated body; offer it as a candidate during Step 5).

### No-categories.yml

If `wisdoms/_categories.yml` is missing or unparseable, halt with error. Do
not invent buckets.

## Verification before declaring done

You MUST be able to answer YES to all of:

- [ ] File written under `wisdoms/<YYYY>/<MM>/<id>.md` (verify with `ls`)
- [ ] Frontmatter parses as valid YAML (verify by reading file back)
- [ ] `id` matches filename
- [ ] `body_hash` matches `sha256(normalize(body))`
- [ ] Commit landed on local `main` (verify with `git log -1 --oneline`)
- [ ] If push happened, `git push` exited 0

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Saving without filling `category` | Step 4 is mandatory; ask user if you cannot pick |
| Using `~` or `null` inconsistently for empty string fields | Always render empty strings as `""` and empty refs as `null` |
| Writing to repo root instead of `wisdoms/` | Re-check Step 7 path construction |
| `git add -A` | Always `git add <specific-file>` |
| `--no-verify` on commit | Never. Fix hook failures instead |
| Inventing a new category color | Use `color_pool` from `_categories.yml`, pop the first unused |
| Renaming an existing category | Out of scope for capture; require explicit user instruction |

See REFERENCE.md for prompt templates and the full JSON output schema.
