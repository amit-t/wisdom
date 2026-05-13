#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/_import_helpers.zsh"
source "$repo_root/lib/cmd_import.zsh"

tmp=$(setup_temp_repo)
WISDOM_REPO=$tmp
trap "teardown_temp_repo $tmp" EXIT

fixture="$tmp/import.txt"
printf 'first paragraph wisdom long enough\n\nsecond paragraph wisdom long enough\n\nthird paragraph wisdom long enough\n' > "$fixture"

_wisdom_import --format txt --no-categorize "$fixture" >/tmp/wis-out 2>&1
n=$(find "$tmp/wisdoms" -name '*.md' | wc -l | tr -d ' ')
assert_eq 3 "$n" "three blank-line-separated paragraphs"
