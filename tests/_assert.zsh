#!/usr/bin/env zsh
# Shared test helpers. Source this from each test.

assert_eq() {
  local expected="$1"
  local actual="$2"
  local msg="${3:-values differ}"
  if [[ "$expected" != "$actual" ]]; then
    print -r -- "  FAIL: $msg" >&2
    print -r -- "    expected: $(print -r -- "$expected" | head -c 200)" >&2
    print -r -- "    actual:   $(print -r -- "$actual"   | head -c 200)" >&2
    exit 1
  fi
}

assert_neq() {
  local a="$1"
  local b="$2"
  local msg="${3:-values are equal but should not be}"
  if [[ "$a" == "$b" ]]; then
    print -r -- "  FAIL: $msg" >&2
    exit 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local msg="${3:-substring not found}"
  if [[ "$haystack" != *"$needle"* ]]; then
    print -r -- "  FAIL: $msg" >&2
    print -r -- "    looking for: $needle" >&2
    print -r -- "    in:          $(print -r -- "$haystack" | head -c 200)" >&2
    exit 1
  fi
}

assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local msg="${3:-exit code mismatch}"
  if (( expected != actual )); then
    print -r -- "  FAIL: $msg (expected $expected, got $actual)" >&2
    exit 1
  fi
}

assert_file_exists() {
  local path="$1"
  # Accept either real files or symlinks (even dangling), since some tasks
  # set up symlinks whose targets are created in a later task.
  if [[ ! -e "$path" && ! -L "$path" ]]; then
    print -r -- "  FAIL: file does not exist: $path" >&2
    exit 1
  fi
}

# Make every test run in a fresh temp WISDOM_REPO unless caller overrides.
setup_temp_repo() {
  local tmp
  tmp=$(mktemp -d -t wisdom-test.XXXXXX)
  mkdir -p "$tmp/wisdoms"
  cp "$WISDOM_SOURCE_REPO/wisdoms/_categories.yml" "$tmp/wisdoms/_categories.yml"
  (cd "$tmp" && git init -q && git add -A && git -c user.email=t@t -c user.name=t commit -q -m init)
  print -r -- "$tmp"
}

teardown_temp_repo() {
  local tmp="$1"
  [[ -n "$tmp" && "$tmp" == /tmp/* || "$tmp" == /var/folders/* ]] && rm -rf "$tmp"
}
