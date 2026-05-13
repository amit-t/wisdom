#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/cmd_find.zsh"

tmp=$(setup_temp_repo)
WISDOM_REPO=$tmp
trap "teardown_temp_repo $tmp" EXIT

mkdir -p "$tmp/wisdoms/2026/05"
cat > "$tmp/wisdoms/2026/05/01jfind001.md" <<'EOF'
---
id: 01jfind001
created_at: 2026-05-13T10:00:00Z
body_hash: aaa
category: engineering
tags: [debugging]
source_url: null
source_author: Rich Hickey
note: ""
import_origin: manual
---

Programming is not about typing, it's about thinking.
EOF

# Match in body
out=$(_wisdom_find "typing" 2>&1)
assert_contains "$out" "01jfind001" "body match"
assert_contains "$out" "typing"     "body line shown"

# Match in author
out=$(_wisdom_find "Hickey" 2>&1)
assert_contains "$out" "01jfind001" "author match"

# No match
out=$(_wisdom_find "nonsense-zzz" 2>&1)
assert_contains "$out" "no matches" "no-match message"

# Missing query
rc=0
_wisdom_find >/tmp/wis-out 2>&1 || rc=$?
assert_exit_code 1 $rc "missing query exits 1"
