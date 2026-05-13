#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"

# Same body, different whitespace + casing -> same hash
h1=$(wisdom_body_hash "Hello   world")
h2=$(wisdom_body_hash "  hello world  ")
h3=$(wisdom_body_hash $'HELLO\n\nworld')
assert_eq "$h1" "$h2" "whitespace-collapse should normalize"
assert_eq "$h1" "$h3" "newline-collapse should normalize"

# Different body -> different hash
h4=$(wisdom_body_hash "hello world!")
assert_neq "$h1" "$h4" "extra punctuation should change hash"

# Length: sha256 hex = 64 chars
assert_eq 64 "${#h1}" "sha256 hex must be 64 chars"
