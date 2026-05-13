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

# Unknown subcommand exits 1
"$repo_root/bin/wisdom" nonsense >/tmp/wis-out 2>&1
rc=$?
assert_exit_code 1 $rc "unknown subcommand"

# Stub subcommands print "not implemented yet" but exit 0
for sub in ls show find edit rm import import-url; do
  "$repo_root/bin/wisdom" $sub >/tmp/wis-out 2>&1
  rc=$?
  assert_exit_code 0 $rc "stub $sub exit code"
  grep -qi 'not implemented' /tmp/wis-out || {
    print -r -- "FAIL: stub $sub must say 'not implemented yet'"; exit 1
  }
done
