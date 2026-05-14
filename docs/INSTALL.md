# Install

## 1. CLI

```bash
git clone <this-repo> ~/Projects/AmitTiwari/wisdom
cd ~/Projects/AmitTiwari/wisdom
./install.sh
```

`install.sh` symlinks `bin/wisdom` → `~/bin/wisdom` and prints the shell
exports you need to add manually.

Add the printed lines to `~/.zshrc` (or your shell's equivalent):

```zsh
export PATH="$HOME/bin:$PATH"
export WISDOM_REPO="$HOME/Projects/AmitTiwari/wisdom"
```

Reload your shell, then verify:

```bash
wisdom --version
wisdom --help
```

## 2. wisdom-capture skill

The skill is published in the [at-skills catalog](https://github.com/amit-t/skills/tree/main/wisdom-capture)
and installed per-project via the `skills` CLI:

```bash
cd ~/Projects/AmitTiwari/wisdom
npx skills@latest add amit-t/skills --skill wisdom-capture
```

That drops the skill at `.claude/skills/wisdom-capture/` (project-level).
Claude auto-discovers it when invoked from this project. Codex / Devin
support is included in the at-skills install paths — see
the [skill README](https://github.com/amit-t/skills/tree/main/wisdom-capture#manual-installation)
for the per-engine destinations if you prefer manual install.

Re-run the same command to upgrade the skill in place after a new at-skills
release.

## 3. GitHub Pages site

1. Push the repo to GitHub.
2. Repo → **Settings → Pages → Source = "GitHub Actions"** (or enable once
   via `gh api -X POST repos/<owner>/<repo>/pages -f build_type=workflow`).
3. Push to `main` triggers the build (`.github/workflows/pages.yml`).
4. Site appears at `https://<owner>.github.io/wisdom/`.

## Per-engine triggers

| Engine | Slash trigger | Notes |
|--------|---------------|-------|
| Claude Code | `/wisdom-capture` | Or just describe the task — the skill description triggers auto-invoke. |
| Devin | `/wisdom-capture` | |
| Codex | `$wisdom-capture` | Codex uses `$` prefix for slash-equivalent commands. |

> The terminal CLI command remains `wisdom "..."`. The slash-command inside an
> agent session is `wisdom-capture` (matches the skill's `name:` field).

## Uninstall

```bash
rm -f ~/bin/wisdom
rm -rf .claude/skills/wisdom-capture
```

Remove the `WISDOM_REPO` and `PATH` lines from your `~/.zshrc`.
