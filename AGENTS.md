# AGENTS.md

This repo is a personal wisdom corpus. Any agent (Claude Code, Codex, Devin)
entering this repo should follow these rules.

## When asked to record a wisdom snippet

Load and follow `.agents/skills/wisdom-capture/SKILL.md` exactly.

In Claude Code, this skill is named `wisdom-capture` and is also reachable via
the `/wisdom` slash-command.
In Devin, use `/wisdom`.
In Codex, use `$wisdom`.

## Repository conventions

- Wisdoms live in `wisdoms/<YYYY>/<MM>/<ulid>.md` with frontmatter per
  `docs/ARCHITECTURE.md` (or `docs/superpowers/plans/2026-05-13-wisdom.md` §C2
  while ARCHITECTURE.md is in progress).
- Categories are closed; the source of truth is `wisdoms/_categories.yml`.
- One commit per snippet. Format: `wisdom: <category> — <body first 60>…`.

## Tests

Run `zsh tests/run.zsh` before declaring work complete.

## What NOT to do

- Do not edit `wisdoms/_categories.yml` to add new buckets without explicit
  user confirmation (the skill handles this interactively).
- Do not batch-rewrite frontmatter across many wisdom files unless asked.
- Do not use `git add -A`. Always stage specific files.
- Do not skip pre-commit hooks (no `--no-verify`).

## amittiwari.me integration

The amittiwari.me Next.js site consumes this repo as a git submodule at
`external/wisdom` and renders the corpus natively. Wisdom is the single
source of truth; the markdown frontmatter (`category`, `tags`, `created_at`,
`source_url`, `source_author`, `note`) is the wire format both sides
consume.

- If you change the frontmatter shape, update the matching types in
  `amittiwari-me/src/lib/wisdom.ts` as well.
- If you rename `wisdoms/_categories.yml` or restructure `wisdoms/<YYYY>/<MM>/`,
  update the data layer there too.

### Auto-redeploy on push

`.github/workflows/trigger-amittiwari-me.yml` POSTs to a DigitalOcean App
Platform deploy webhook whenever main moves, so a new `wisdom "..."` capture
goes live on amittiwari.me without manual intervention.

One-time setup (only needed when the webhook URL rotates or the repo is
re-forked):
1. DO console → amittiwari-me app → Settings → App-Level → Deploy Triggers
   → create a webhook and copy the URL.
2. This repo → Settings → Secrets and variables → Actions → New secret:
   `AMITTIWARI_ME_DO_DEPLOY_WEBHOOK = <url>`.

Until the secret exists, the workflow runs but emits a warning and skips
the POST; pushes are not blocked.
