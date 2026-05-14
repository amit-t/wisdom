#!/usr/bin/env zsh
# Wisdom installer: symlinks bin/wisdom into ~/bin. Idempotent.
#
# The wisdom-capture skill is NOT installed by this script. It is published in
# the at-skills catalog and installed per-project via the `skills` CLI:
#
#   npx skills@latest add amit-t/skills --skill wisdom-capture
#
# Run that from inside this repo (or any consumer repo). The skill lands at
# `.claude/skills/wisdom-capture/` (project-level) and Claude auto-discovers
# it when invoked from this project.

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

print -r -- "Installing wisdom CLI from: $repo_root"

link_or_replace "$repo_root/bin/wisdom" "$HOME/bin/wisdom"

print
print -r -- "Add these lines to your ~/.zshrc (or equivalent):"
print -r -- ""
print -r -- "    export PATH=\"\$HOME/bin:\$PATH\""
print -r -- "    export WISDOM_REPO=\"$repo_root\""
print -r -- ""
print -r -- "Install the wisdom-capture skill into this project:"
print -r -- ""
print -r -- "    cd $repo_root"
print -r -- "    npx skills@latest add amit-t/skills --skill wisdom-capture"
print -r -- ""
print -r -- "Done. Try: wisdom --help"
