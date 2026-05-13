#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/_import_helpers.zsh"
source "$repo_root/lib/cmd_import.zsh"

if ! (( $+commands[python3] )); then
  print -r -- "SKIP: python3 not on \$PATH"; exit 0
fi
if ! (( $+commands[jq] )); then
  print -r -- "SKIP: jq not on \$PATH"; exit 0
fi

tmp=$(setup_temp_repo)
WISDOM_REPO=$tmp
trap "teardown_temp_repo $tmp" EXIT

fixture="$tmp/import.csv"
cat > "$fixture" <<'EOF'
body,source_url,source_author,note,category,tags
"First wisdom row.","https://a.com","Author A","note A","engineering","x|y"
"Second wisdom row.",,,"note B","writing","z"
EOF

rc=0
_wisdom_import --format csv --no-categorize "$fixture" >/tmp/wis-out 2>&1 || rc=$?
assert_exit_code 0 $rc "csv import success"

n=$(find "$tmp/wisdoms" -name '*.md' | wc -l | tr -d ' ')
assert_eq 2 "$n" "two wisdoms"
