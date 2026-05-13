#!/usr/bin/env zsh
# Wisdom installer: symlinks bin/wisdom and the skill into engine-specific dirs.
# Idempotent; safe to re-run.

set -e
script_path=${0:A}
repo_root=${script_path:h}

mkdir -p "$HOME/bin"

link_or_replace() {
  local src="$1" dst="$2"
  mkdir -p "${dst:h}"
  if [[ -L "$dst" ]]; then
    rm -f "$dst"
  elif [[ -e "$dst" ]]; then
    print -r -- "install: $dst exists and is not a symlink; skipping" >&2
    return 0
  fi
  ln -s "$src" "$dst"
  print -r -- "  linked $dst -> $src"
}

print -r -- "Installing wisdom CLI + skill from: $repo_root"

# CLI
link_or_replace "$repo_root/bin/wisdom" "$HOME/bin/wisdom"

# Skill (canonical location → engine-specific skill dirs)
local skill="$repo_root/.agents/skills/wisdom-capture"
for engine in claude codex devin; do
  link_or_replace "$skill" "$HOME/.$engine/skills/wisdom-capture"
done

print
print -r -- "Add these lines to your ~/.zshrc (or equivalent):"
print -r -- ""
print -r -- "    export PATH=\"\$HOME/bin:\$PATH\""
print -r -- "    export WISDOM_REPO=\"$repo_root\""
print -r -- ""
print -r -- "Done. Try: wisdom --help"
