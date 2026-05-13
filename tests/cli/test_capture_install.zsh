#!/usr/bin/env zsh
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"

# Run install.sh in a fake HOME so we don't touch the real one.
fake_home=$(mktemp -d -t wisdom-home.XXXXXX)
HOME=$fake_home zsh "$repo_root/install.sh" >/tmp/wis-out 2>&1
rc=$?
assert_exit_code 0 $rc "install.sh exit code"

# CLI symlink created
assert_file_exists "$fake_home/bin/wisdom"

# CLI symlink points back into the repo
target=$(readlink "$fake_home/bin/wisdom")
assert_contains "$target" "bin/wisdom" "bin symlink target"

# install.sh no longer touches global skill dirs (skill is installed via
# `npx skills@latest add amit-t/skills --skill wisdom-capture` per-project)
[[ ! -e "$fake_home/.claude/skills/wisdom-capture" ]] || {
  print -r -- "FAIL: install.sh must NOT create ~/.claude/skills/wisdom-capture"; exit 1
}
[[ ! -e "$fake_home/.codex/skills/wisdom-capture" ]] || {
  print -r -- "FAIL: install.sh must NOT create ~/.codex/skills/wisdom-capture"; exit 1
}
[[ ! -e "$fake_home/.devin/skills/wisdom-capture" ]] || {
  print -r -- "FAIL: install.sh must NOT create ~/.devin/skills/wisdom-capture"; exit 1
}

# Re-run is idempotent
HOME=$fake_home zsh "$repo_root/install.sh" >/tmp/wis-out 2>&1
rc=$?
assert_exit_code 0 $rc "re-run is idempotent"

# Output mentions WISDOM_REPO + npx skill install hint
grep -q WISDOM_REPO /tmp/wis-out || { print -r -- "FAIL: install.sh must print WISDOM_REPO export hint"; exit 1; }
grep -q "npx skills" /tmp/wis-out || { print -r -- "FAIL: install.sh must print npx install hint"; exit 1; }

rm -rf "$fake_home"
