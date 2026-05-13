#!/usr/bin/env zsh
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"

# Under min -> nonzero exit
wisdom_check_length "ok" >/tmp/wis-out 2>&1
rc=$?
assert_eq 6 "$rc" "too short must exit 6"

# Empty -> nonzero exit
wisdom_check_length "" >/tmp/wis-out 2>&1
rc=$?
assert_eq 6 "$rc" "empty must exit 6"

# Normal -> success
wisdom_check_length "Programming is not about typing, it's about thinking." >/tmp/wis-out 2>&1
rc=$?
assert_eq 0 "$rc" "normal length must pass"

# Long but under max -> success (warn allowed)
long=$(printf 'x%.0s' {1..3000})
wisdom_check_length "$long" >/tmp/wis-out 2>&1
rc=$?
assert_eq 0 "$rc" "3000 chars must pass"

# Over max -> warn but still pass (exit 0)
huge=$(printf 'x%.0s' {1..5500})
wisdom_check_length "$huge" >/tmp/wis-out 2>&1
rc=$?
assert_eq 0 "$rc" "over max should warn but succeed"
grep -q 'long' /tmp/wis-out || { print -r -- "FAIL: expected warning text"; exit 1; }
