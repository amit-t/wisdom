#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/_url_helpers.zsh"
source "$repo_root/lib/cmd_import_url.zsh"

if ! (( $+commands[ffmpeg] )); then
  print -r -- "SKIP: ffmpeg not on \$PATH"; exit 0
fi

tmp=$(setup_temp_repo)
WISDOM_REPO=$tmp
trap "teardown_temp_repo $tmp" EXIT

cache=$(wisdom_url_cache_dir "https://example.com/v")
# Generate a 5-second test video
ffmpeg -f lavfi -i testsrc=duration=5:size=320x240:rate=10 -pix_fmt yuv420p \
       -c:v libx264 -preset ultrafast "$cache/video.mp4" -y >/dev/null 2>&1

_wisdom_url_keyframes "$cache"

# Should produce at least one keyframe under cache/keyframes/
n=$(ls "$cache/keyframes/"*.jpg 2>/dev/null | wc -l | tr -d ' ')
(( n >= 1 )) || { print -r -- "FAIL: no keyframes extracted"; exit 1; }
