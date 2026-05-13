#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/_url_helpers.zsh"

tmp=$(setup_temp_repo)
WISDOM_REPO=$tmp
trap "teardown_temp_repo $tmp" EXIT

# Cache dir path is deterministic for a URL
url="https://www.instagram.com/reel/abcdef/"
h1=$(wisdom_url_hash "$url")
h2=$(wisdom_url_hash "$url")
assert_eq "$h1" "$h2" "url hash deterministic"
assert_eq 64 "${#h1}" "sha256 hex length"

# Cache dir creation
dir=$(wisdom_url_cache_dir "$url")
assert_contains "$dir" ".cache/imports/" "cache path under .cache/imports"
[[ -d "$dir" ]] || { echo "FAIL: cache dir not created"; exit 1; }

# Domain detection
assert_eq "instagram" "$(wisdom_url_domain "$url")"
assert_eq "youtube"   "$(wisdom_url_domain "https://www.youtube.com/watch?v=abc")"
assert_eq "twitter"   "$(wisdom_url_domain "https://twitter.com/u/status/123")"
assert_eq "twitter"   "$(wisdom_url_domain "https://x.com/u/status/123")"
assert_eq "tiktok"    "$(wisdom_url_domain "https://www.tiktok.com/@u/video/123")"
assert_eq "other"     "$(wisdom_url_domain "https://example.com/post/5")"
