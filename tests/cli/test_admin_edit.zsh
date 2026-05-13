#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/cmd_edit.zsh"

tmp=$(setup_temp_repo)
WISDOM_REPO=$tmp
trap "teardown_temp_repo $tmp" EXIT

mkdir -p "$tmp/wisdoms/2026/05"
cat > "$tmp/wisdoms/2026/05/01jedit001.md" <<'EOF'
---
id: 01jedit001
created_at: 2026-05-13T10:00:00Z
body_hash: aaa
category: engineering
tags: []
source_url: null
source_author: null
note: ""
import_origin: manual
---

Original body.
EOF

(cd "$tmp" && git add -A && git -c user.email=t@t -c user.name=t commit -q -m seed)

# Mock editor: rewrite body
fake_editor=$(mktemp -d)/fake-ed.zsh
cat > "$fake_editor" <<'EOF'
#!/usr/bin/env zsh
file=$1
content=$(cat "$file")
print -r -- "${content//Original body./Edited body.}" > "$file"
EOF
chmod +x "$fake_editor"

rc=0
WISDOM_EDITOR="$fake_editor" _wisdom_edit 01jedit001 --no-recat >/tmp/wis-out 2>&1 || rc=$?
assert_exit_code 0 $rc "edit must succeed"

new_body=$(awk '/^---$/{n++; next} n==2 && NF{print}' "$tmp/wisdoms/2026/05/01jedit001.md")
assert_contains "$new_body" "Edited body" "body must be updated"

# Commit landed
log=$(cd "$tmp" && git log -1 --pretty=%s)
assert_contains "$log" "wisdom: edit 01jedi" "edit commit subject"
