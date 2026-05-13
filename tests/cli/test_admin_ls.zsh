#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/cmd_ls.zsh"

tmp=$(setup_temp_repo)
WISDOM_REPO=$tmp
trap "teardown_temp_repo $tmp" EXIT

# Empty case
out=$(_wisdom_ls 2>&1)
assert_contains "$out" "no wisdoms" "empty repo message"

# Seed three wisdoms
mkdir -p "$tmp/wisdoms/2026/05"
for i in 1 2 3; do
  cat > "$tmp/wisdoms/2026/05/01jls$i.md" <<EOF
---
id: 01jls$i
created_at: 2026-05-0${i}T10:00:00Z
body_hash: aaa
category: engineering
tags: [a, b]
source_url: null
source_author: null
note: ""
import_origin: manual
---

Wisdom body number $i
EOF
done

out=$(_wisdom_ls 2>&1)
for i in 1 2 3; do
  assert_contains "$out" "01jls$i" "ls must list 01jls$i"
done

# --bucket filter
mkdir -p "$tmp/wisdoms/2026/04"
cat > "$tmp/wisdoms/2026/04/01jlsleader.md" <<EOF
---
id: 01jlsleader
created_at: 2026-04-01T10:00:00Z
body_hash: bbb
category: leadership
tags: []
source_url: null
source_author: null
note: ""
import_origin: manual
---

Leader body
EOF

out=$(_wisdom_ls --bucket leadership 2>&1)
assert_contains "$out" "01jlsleader" "bucket filter must include leadership"
[[ "$out" != *01jls1* ]] || { echo "FAIL: bucket filter must EXCLUDE engineering"; exit 1; }

# --limit
out=$(_wisdom_ls --limit 1 2>&1)
# Recent-first ordering: 2026-05-03 > others; first row should be 01jls3
assert_contains "$out" "01jls3" "limit 1 first row should be newest"
