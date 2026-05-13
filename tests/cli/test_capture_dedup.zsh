#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"

tmp=$(setup_temp_repo)
WISDOM_REPO=$tmp

# Seed a wisdom file with a known body_hash
mkdir -p "$tmp/wisdoms/2026/05"
hash=$(wisdom_body_hash "First wisdom")
cat > "$tmp/wisdoms/2026/05/01jaaa.md" <<EOF
---
id: 01jaaa
created_at: 2026-05-13T00:00:00Z
body_hash: $hash
category: engineering
tags: []
source_url: null
source_author: null
note: ""
import_origin: manual
---

First wisdom
EOF

# Dedup hit: same normalized body
match=$(wisdom_find_dup "first wisdom" "$tmp")
assert_contains "$match" "01jaaa" "should find existing entry by hash"

# Dedup miss: different body
match=$(wisdom_find_dup "second wisdom" "$tmp")
assert_eq "" "$match" "different body should not match"

teardown_temp_repo "$tmp"
