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

# Override per-URL handler to just log
_wisdom_import_url_one() {
  local url="$1"
  print -r -- "PROCESSED: $url" >> "$tmp/batch.log"
  return 0
}

# Disable scrape-only side effects for this test
_wisdom_url_scrape_only() { return 0 ; }

_wisdom_import_url \
  "https://example.com/1" \
  "https://example.com/2" \
  "https://example.com/3"

n=$(grep -c PROCESSED "$tmp/batch.log")
assert_eq 3 "$n" "all three URLs processed"
