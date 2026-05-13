#!/usr/bin/env zsh
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"

# Run install.sh in a fake HOME so we don't touch the real one.
fake_home=$(mktemp -d -t wisdom-home.XXXXXX)
HOME=$fake_home zsh "$repo_root/install.sh" >/tmp/wis-out 2>&1
rc=$?
assert_exit_code 0 $rc "install.sh exit code"

# Symlinks created
assert_file_exists "$fake_home/bin/wisdom"
assert_file_exists "$fake_home/.claude/skills/wisdom-capture"
assert_file_exists "$fake_home/.codex/skills/wisdom-capture"
assert_file_exists "$fake_home/.devin/skills/wisdom-capture"

# Symlinks point back into the repo
target=$(readlink "$fake_home/bin/wisdom")
assert_contains "$target" "bin/wisdom" "bin symlink target"

target=$(readlink "$fake_home/.claude/skills/wisdom-capture")
assert_contains "$target" ".agents/skills/wisdom-capture" "claude skill symlink target"

# Re-run is idempotent
HOME=$fake_home zsh "$repo_root/install.sh" >/tmp/wis-out 2>&1
rc=$?
assert_exit_code 0 $rc "re-run is idempotent"

# Output mentions WISDOM_REPO line for shell profile
grep -q WISDOM_REPO /tmp/wis-out || { print -r -- "FAIL: install.sh must print WISDOM_REPO export hint"; exit 1; }

rm -rf "$fake_home"
