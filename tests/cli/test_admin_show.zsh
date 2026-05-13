#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/cmd_show.zsh"

tmp=$(setup_temp_repo)
WISDOM_REPO=$tmp
trap "teardown_temp_repo $tmp" EXIT

mkdir -p "$tmp/wisdoms/2026/05"
cat > "$tmp/wisdoms/2026/05/01jshow001.md" <<'EOF'
---
id: 01jshow001
created_at: 2026-05-13T10:00:00Z
body_hash: aaa
category: engineering
tags: [foo, bar]
source_url: https://example.com/x
source_author: Someone
note: "my note"
import_origin: manual
---

Body of the shown wisdom.
EOF

# Resolve by full id
out=$(_wisdom_show 01jshow001 2>&1)
assert_contains "$out" "Body of the shown wisdom" "must show body"
assert_contains "$out" "engineering" "must show category"
assert_contains "$out" "Someone" "must show author"
assert_contains "$out" "my note" "must show note"

# Resolve by prefix
out=$(_wisdom_show 01jshow 2>&1)
assert_contains "$out" "Body of the shown wisdom" "prefix resolve"

# Missing id -> nonzero
rc=0
_wisdom_show 99zzz9 >/tmp/wis-out 2>&1 || rc=$?
assert_exit_code 1 $rc "missing id must exit 1"

# Ambiguous prefix -> menu
cat > "$tmp/wisdoms/2026/05/01jshow002.md" <<'EOF'
---
id: 01jshow002
created_at: 2026-05-13T11:00:00Z
body_hash: bbb
category: writing
tags: []
source_url: null
source_author: null
note: ""
import_origin: manual
---

Another wisdom.
EOF
out=$(_wisdom_show 01jsh 2>&1 || true)
assert_contains "$out" "01jshow001" "ambiguous lists 001"
assert_contains "$out" "01jshow002" "ambiguous lists 002"
