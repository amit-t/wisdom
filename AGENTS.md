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

## Embed mode (amittiwari.me integration)

Wisdom is also rendered inside `https://amittiwari.me/wisdom` via a cross-origin
iframe. When loaded with `?embed=1`, the layout strips its own nav, theme
switcher, and footer (the host page provides those) and aligns its design
tokens to amittiwari.me's palette.

- Implementation: `assets/js/site.js` reads `?embed=1` + `?theme=…`, listens for
  `postMessage({type:'wisdom:theme', theme})` from `https://amittiwari.me`, and
  rewrites internal `<a href>` clicks to preserve the embed flag so deep links
  stay inside the embed.
- CSS lives under `body.embed` selectors in `assets/css/site.css`.
- The standalone site (without `?embed=1`) is unchanged.
- If you change selectors or class names on `.site-nav`, `.theme-switcher`, or
  `.footer`, update the embed selectors too.
