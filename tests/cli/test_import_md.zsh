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

# Single-file markdown with two snippets separated by `---`
fixture="$tmp/import.md"
cat > "$fixture" <<'EOF'
First wisdom is about engineering. Premature optimization is the root of all evil. — Knuth

---

Second wisdom about leadership. A decision without an owner is a wish.
EOF

# --dry-run: count + preview, no writes
out=$(_wisdom_import --format md --dry-run --no-categorize "$fixture" 2>&1)
assert_contains "$out" "would import 2" "dry-run count"
n_before=$(find "$tmp/wisdoms" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
[[ "$n_before" == "0" ]] || { echo "FAIL: dry-run wrote files (found $n_before)"; exit 1; }

# Real run with --no-categorize (writes uncategorized, default to 'life')
out=$(_wisdom_import --format md --no-categorize "$fixture" 2>&1)
n=$(find "$tmp/wisdoms" -name '*.md' | wc -l | tr -d ' ')
assert_eq 2 "$n" "two wisdoms must be written"

# Commit landed
log=$(cd "$tmp" && git log -1 --pretty=%s)
assert_contains "$log" "wisdom: import 2 entries" "import commit subject"
