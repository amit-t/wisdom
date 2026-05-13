#!/usr/bin/env zsh
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"

# --help exits 0 and lists subcommands
out=$("$repo_root/bin/wisdom" --help 2>&1)
rc=$?
assert_exit_code 0 $rc "--help exit code"
for sub in ls show find edit rm import import-url; do
  assert_contains "$out" "$sub" "--help must mention $sub"
done

# --version prints something
out=$("$repo_root/bin/wisdom" --version 2>&1)
rc=$?
assert_exit_code 0 $rc "--version exit code"
assert_contains "$out" "wisdom" "--version output"

# Single bare token under length-guard min is treated as a positional snippet
# and rejected by the length guard with exit 6 (not "unknown subcommand").
"$repo_root/bin/wisdom" nonsense >/tmp/wis-out 2>&1
rc=$?
assert_exit_code 6 $rc "short positional snippet rejected by length guard"

# Subcommands route (real impls in P3; ls/show/find/edit/rm/import/import-url).
# `ls` on an empty repo prints "no wisdoms yet". `import`/`import-url` without
# args print a usage error and exit 1. `show`/`edit`/`rm` without args exit 1.
# We assert routing happens (exit code as expected for each subcommand's
# no-arg invocation).
tmp_repo=$(mktemp -d -t wisdom-dispatch.XXXXXX)
mkdir -p "$tmp_repo/wisdoms"
cp "$repo_root/wisdoms/_categories.yml" "$tmp_repo/wisdoms/_categories.yml"

# `ls` with no args on empty repo -> exit 0, mentions wisdoms
WISDOM_REPO="$tmp_repo" "$repo_root/bin/wisdom" ls >/tmp/wis-out 2>&1
rc=$?
assert_exit_code 0 $rc "ls exit code on empty repo"
grep -qi 'no wisdoms\|wisdom' /tmp/wis-out || {
  print -r -- "FAIL: ls must produce some output"; exit 1
}

# Subcommands that require an arg exit 1 with usage error
for sub in show find edit rm import import-url; do
  WISDOM_REPO="$tmp_repo" "$repo_root/bin/wisdom" $sub >/tmp/wis-out 2>&1
  rc=$?
  assert_exit_code 1 $rc "$sub without arg must exit 1"
done

rm -rf "$tmp_repo"
