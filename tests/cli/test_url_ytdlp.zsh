#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/_url_helpers.zsh"
source "$repo_root/lib/cmd_import_url.zsh"

if ! (( $+commands[yt-dlp] )); then
  print -r -- "SKIP: yt-dlp not on \$PATH"; exit 0
fi

tmp=$(setup_temp_repo)
WISDOM_REPO=$tmp
trap "teardown_temp_repo $tmp" EXIT

url="https://www.youtube.com/watch?v=jNQXAC9IVRw"
cache=$(wisdom_url_cache_dir "$url")

if ! curl -sf -o /dev/null --connect-timeout 5 https://www.youtube.com; then
  print -r -- "SKIP: no network access"; exit 0
fi

_wisdom_url_scrape_ytdlp "$url" "$cache" || { print -r -- "FAIL: yt-dlp failed"; exit 1; }

assert_file_exists "$cache/meta.json"
# Either audio.* or thumb.* should exist
audio_or_thumb=0
for ext in mp3 m4a wav webm jpg png webp jpeg; do
  [[ -f "$cache/audio.$ext" || -f "$cache/thumb.$ext" ]] && audio_or_thumb=1
done
[[ "$audio_or_thumb" == "1" ]] || { print -r -- "FAIL: no media saved"; exit 1; }

# Metadata has title + uploader
title=$(jq -r .title "$cache/meta.json")
[[ -n "$title" && "$title" != "null" ]] || { print -r -- "FAIL: title missing"; exit 1; }
