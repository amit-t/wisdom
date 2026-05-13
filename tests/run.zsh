#!/usr/bin/env zsh
# Test runner. Walks tests/cli, tests/skill, tests/site; runs each .zsh; reports.

set -u
setopt NULL_GLOB
script_path=${0:A}
repo_root=${script_path:h:h}
export WISDOM_SOURCE_REPO="$repo_root"

pass=0
fail=0
skip=0
failed_tests=()
skipped_tests=()

for dir in tests/cli tests/skill tests/site; do
  [[ -d "$repo_root/$dir" ]] || continue
  for test in "$repo_root"/$dir/test_*.zsh; do
    [[ -f "$test" ]] || continue
    name="${test#$repo_root/}"
    if zsh "$test" >/tmp/wisdom-test.out 2>&1; then
      if grep -q '^SKIP:' /tmp/wisdom-test.out; then
        (( skip++ ))
        skipped_tests+=("$name")
        print -r -- "  SKIP $name"
      else
        (( pass++ ))
        print -r -- "  PASS $name"
      fi
    else
      (( fail++ ))
      failed_tests+=("$name")
      print -r -- "  FAIL $name"
      print -r -- "    ---"
      sed 's/^/    /' /tmp/wisdom-test.out
      print -r -- "    ---"
    fi
  done
done

print
print -r -- "$pass passed, $fail failed, $skip skipped"
exit $(( fail > 0 ? 1 : 0 ))
