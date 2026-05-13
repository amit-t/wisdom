#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/_url_helpers.zsh"
source "$repo_root/lib/cmd_import_url.zsh"

tmp=$(setup_temp_repo)
WISDOM_REPO=$tmp
trap "teardown_temp_repo $tmp" EXIT

# Seed an existing wisdom with source_url = our URL
mkdir -p "$tmp/wisdoms/2026/05"
cat > "$tmp/wisdoms/2026/05/01jreimp01.md" <<'EOF'
---
id: 01jreimp01
created_at: 2026-05-13T10:00:00Z
body_hash: aaa
category: engineering
tags: []
source_url: https://www.instagram.com/reel/abcdef/
source_author: null
note: ""
import_origin: url:https://www.instagram.com/reel/abcdef/
---

Existing wisdom body.
EOF

# Non-interactive: WISDOM_REIMPORT_DEFAULT=skip
rc=0
WISDOM_REIMPORT_DEFAULT=skip _wisdom_url_check_reimport "https://www.instagram.com/reel/abcdef/" >/tmp/wis-out 2>&1 || rc=$?
assert_exit_code 0 $rc "skip path returns 0"
grep -q "already imported" /tmp/wis-out

# No match
rc=0
WISDOM_REIMPORT_DEFAULT=skip _wisdom_url_check_reimport "https://example.com/never" >/tmp/wis-out 2>&1 || rc=$?
assert_exit_code 1 $rc "no match returns 1"
