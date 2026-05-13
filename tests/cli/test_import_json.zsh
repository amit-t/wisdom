#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/_import_helpers.zsh"
source "$repo_root/lib/cmd_import.zsh"

if ! (( $+commands[jq] )); then
  print -r -- "SKIP: jq not on \$PATH"; exit 0
fi

tmp=$(setup_temp_repo)
WISDOM_REPO=$tmp
trap "teardown_temp_repo $tmp" EXIT

fixture="$tmp/import.json"
cat > "$fixture" <<'EOF'
[
  {"body": "First wisdom about engineering.", "source_author": "Knuth", "source_url": "https://example.com/k"},
  {"body": "Second wisdom about leadership.", "category": "leadership", "tags": ["clarity"]}
]
EOF

rc=0
_wisdom_import --format json --no-categorize "$fixture" >/tmp/wis-out 2>&1 || rc=$?
assert_exit_code 0 $rc "json import success"

n=$(find "$tmp/wisdoms" -name '*.md' | wc -l | tr -d ' ')
assert_eq 2 "$n" "two wisdoms"

# Verify category for record with explicit category
files=("$tmp"/wisdoms/**/*.md)
got_leader=0
for f in $files; do
  cat=$(awk -F': ' '/^category:/{print $2; exit}' "$f")
  [[ "$cat" == "leadership" ]] && got_leader=1
done
assert_eq 1 "$got_leader" "leadership record must keep its category"
