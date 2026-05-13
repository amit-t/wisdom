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

cache=$(wisdom_url_cache_dir "https://example.com/x")
# Fake audio (just an empty file; transcriber is mocked)
print -r -- "" > "$cache/audio.mp3"

# Mock the implementation hook used by _wisdom_url_transcribe
_wisdom_whisper_local() {
  local audio="$1" out="$2"
  print -r -- "MOCK transcript local" > "$out"
}
_wisdom_whisper_api() {
  local audio="$1" out="$2"
  print -r -- "MOCK transcript api" > "$out"
}

WISDOM_WHISPER=local _wisdom_url_transcribe "$cache"
got=$(<"$cache/transcript.txt")
assert_eq "MOCK transcript local" "$got" "local whisper mock"

WISDOM_WHISPER=api _wisdom_url_transcribe "$cache"
got=$(<"$cache/transcript.txt")
assert_eq "MOCK transcript api" "$got" "api whisper mock"
