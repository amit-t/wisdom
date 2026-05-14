# AGENTS.md

This repo is a personal wisdom corpus. Any agent (Claude Code, Codex, Devin)
entering this repo should follow these rules.

## When asked to record a wisdom snippet

Load and follow the `wisdom-capture` skill exactly.

The skill is installed per-project from the at-skills catalog. Engine-specific
locations after install:

- Claude Code: `.claude/skills/wisdom-capture/SKILL.md` (project-level)
- Devin / Windsurf: `.cognition/skills/wisdom-capture/SKILL.md`
- Cursor: `.cursor/skills/wisdom-capture/SKILL.md`
- Codex: skill content is concatenated into this `AGENTS.md` by the installer

If you cannot find the skill in any of those locations, the user has not run
the installer yet. From the repo root:

```bash
npx skills@latest add amit-t/skills --skill wisdom-capture
```

Triggers inside an agent session:

- Claude Code: `/wisdom-capture` (or just describe the task — the skill
  description triggers auto-invoke)
- Devin: `/wisdom-capture`
- Codex: `$wisdom-capture`

The terminal CLI shortcut is `wisdom "..."` — that command launches an agent
session in this repo with the snippet pre-fed; the skill takes over from
there.

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

## Pushing changes

Direct push to `main` is policy-blocked. When `git push origin main` is denied
with a direct-push-to-main reason, do NOT surface that as a dead end. Fall
back automatically:

1. Create a topic branch at the current HEAD (e.g. `wisdom/<ulid-prefix>` for
   wisdom commits, `fix/<slug>` / `feat/<slug>` otherwise).
2. Reset local `main` to `origin/main` so it stays clean.
3. Push the topic branch.
4. Open a PR to `main` with `gh pr create`.

Report the PR URL back to the user. This applies to all agents, not just the
wisdom flow.

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

`.github/workflows/trigger-amittiwari-me.yml` calls the DigitalOcean API on
every push to main and asks App Platform to redeploy the amittiwari.me
app, so a new `wisdom "..."` capture goes live without manual steps.

One-time setup (only when the token rotates or the app is re-created):
1. Create a DO Personal Access Token at
   `https://cloud.digitalocean.com/account/api/tokens` with `apps:read` +
   `apps:write` scopes (or full read/write if your account doesn't show
   scopes).
2. Grab the App ID for amittiwari.me from the DO console — open the app
   and copy the UUID in the URL (`/apps/<uuid>`) — or run
   `doctl apps list`.
3. This repo → Settings → Secrets and variables → Actions → add both:
   - `DO_API_TOKEN` = token from step 1
   - `DO_APP_ID` = UUID from step 2

Missing either secret turns the workflow into a no-op with a warning, so
pushes are never blocked.
