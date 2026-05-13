# Install

## One-shot

```bash
git clone <this-repo> ~/Projects/AmitTiwari/wisdom
cd ~/Projects/AmitTiwari/wisdom
./install.sh
```

`install.sh` does:

1. Symlinks `bin/wisdom` → `~/bin/wisdom`
2. Symlinks `.agents/skills/wisdom-capture/` into:
   - `~/.claude/skills/wisdom-capture` (Claude Code)
   - `~/.codex/skills/wisdom-capture` (Codex)
   - `~/.devin/skills/wisdom-capture` (Devin)
3. Prints the shell exports you need to add manually.

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

## Enabling the GitHub Pages site

After Phase 2 lands:

1. Push the repo to GitHub.
2. Repo → **Settings → Pages → Source = "GitHub Actions"**.
3. Push to `main` triggers the build (`.github/workflows/pages.yml`).
4. Site appears at `https://<owner>.github.io/wisdom/`.

## Per-engine triggers

| Engine | Slash trigger | Notes |
|--------|---------------|-------|
| Claude Code | `/wisdom` | Or just describe the task — the skill description triggers auto-invoke. |
| Devin | `/wisdom` | |
| Codex | `$wisdom` | Codex uses `$` prefix for slash-equivalent commands. |

## Uninstall

```bash
rm -f ~/bin/wisdom ~/.claude/skills/wisdom-capture ~/.codex/skills/wisdom-capture ~/.devin/skills/wisdom-capture
```

Remove the `WISDOM_REPO` and `PATH` lines from your `~/.zshrc`.
