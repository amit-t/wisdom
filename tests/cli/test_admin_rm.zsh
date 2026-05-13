#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/cmd_rm.zsh"

tmp=$(setup_temp_repo)
WISDOM_REPO=$tmp
trap "teardown_temp_repo $tmp" EXIT

mkdir -p "$tmp/wisdoms/2026/05"
cat > "$tmp/wisdoms/2026/05/01jrm0001.md" <<'EOF'
---
id: 01jrm0001
created_at: 2026-05-13T10:00:00Z
body_hash: aaa
category: engineering
tags: []
source_url: null
source_author: null
note: ""
import_origin: manual
---

To be removed.
EOF
(cd "$tmp" && git add -A && git -c user.email=t@t -c user.name=t commit -q -m seed)

# Non-interactive removal: --yes
rc=0
_wisdom_rm --yes 01jrm0001 >/tmp/wis-out 2>&1 || rc=$?
assert_exit_code 0 $rc "rm --yes must succeed"
[[ ! -e "$tmp/wisdoms/2026/05/01jrm0001.md" ]] || { echo "FAIL: file still exists"; exit 1; }

log=$(cd "$tmp" && git log -1 --pretty=%s)
assert_contains "$log" "wisdom: remove 01jrm0" "rm commit subject"

# Missing id -> nonzero
rc=0
_wisdom_rm --yes 99zzzz9 >/tmp/wis-out 2>&1 || rc=$?
assert_exit_code 1 $rc "missing id exits 1"
