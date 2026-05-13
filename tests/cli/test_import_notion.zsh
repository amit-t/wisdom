#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/_import_helpers.zsh"
source "$repo_root/lib/cmd_import.zsh"

if ! (( $+commands[unzip] )); then
  print -r -- "SKIP: unzip not available"; exit 0
fi
if ! (( $+commands[zip] )); then
  print -r -- "SKIP: zip not available"; exit 0
fi

tmp=$(setup_temp_repo)
WISDOM_REPO=$tmp
trap "teardown_temp_repo $tmp" EXIT

# Build a minimal "Notion export" zip: two markdown files in a folder
src="$tmp/notion-src"
mkdir -p "$src/Wisdoms ab12cd"
printf '# A wisdom\n\nFirst wisdom from Notion.\n' > "$src/Wisdoms ab12cd/Page One ef34gh.md"
printf '# Another wisdom\n\nSecond wisdom from Notion.\n' > "$src/Wisdoms ab12cd/Page Two ij56kl.md"
(cd "$src" && zip -qr "$tmp/export.zip" "Wisdoms ab12cd")

_wisdom_import --format notion-export --no-categorize "$tmp/export.zip" >/tmp/wis-out 2>&1
n=$(find "$tmp/wisdoms" -name '*.md' | wc -l | tr -d ' ')
assert_eq 2 "$n" "two Notion markdown pages -> two wisdoms"
