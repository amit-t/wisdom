#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"

# Honors WISDOM_REPO env when set
WISDOM_REPO=/tmp/foo wisdom_repo_path >/tmp/wis-out 2>&1 || true
got=$(<"/tmp/wis-out")
assert_eq "/tmp/foo" "$got" "respects WISDOM_REPO env"

# Falls back to default when unset (just verify it's an absolute path; the
# default location may or may not exist in CI)
unset WISDOM_REPO
got=$(wisdom_repo_path 2>/dev/null || true)
[[ "$got" = /* ]] || { print -r -- "FAIL: default repo path must be absolute, got '$got'"; exit 1; }
