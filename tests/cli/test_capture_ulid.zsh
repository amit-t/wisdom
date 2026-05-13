#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"

# Generate one ULID
id=$(wisdom_ulid)

# Crockford base32, 26 chars, lowercase
assert_eq 26 "${#id}" "ULID length must be 26"
[[ "$id" =~ '^[0-9a-hjkmnp-tv-z]{26}$' ]] || { print -r -- "FAIL: ULID alphabet"; exit 1; }

# Two ULIDs in same second differ (entropy)
a=$(wisdom_ulid); b=$(wisdom_ulid)
assert_neq "$a" "$b" "Two ULIDs must differ"

# Monotonic when called in order: lexicographic order matches creation order
sleep 0.01
c=$(wisdom_ulid)
[[ "$a" < "$c" ]] || { print -r -- "FAIL: ULID lexicographic order"; exit 1; }
