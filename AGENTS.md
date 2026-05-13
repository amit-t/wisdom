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
