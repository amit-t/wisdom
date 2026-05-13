# URL ingestion helpers.

# Compute sha256 of a URL (used for cache dir naming).
wisdom_url_hash() {
  local url="$1"
  if (( $+commands[shasum] )); then
    print -r -- "$url" | shasum -a 256 | awk '{print $1}'
  else
    print -r -- "$url" | sha256sum | awk '{print $1}'
  fi
}

# Path of cache dir for a URL; creates it if missing.
wisdom_url_cache_dir() {
  local url="$1" repo h
  repo=$(wisdom_repo_path) || return 2
  h=$(wisdom_url_hash "$url")
  local dir="$repo/.cache/imports/$h"
  mkdir -p "$dir"
  print -r -- "$dir"
}

# Classify the URL host to one of: instagram, twitter, youtube, tiktok, vimeo, other
wisdom_url_domain() {
  local url="$1"
  case "$url" in
    *instagram.com*) print -r -- instagram ;;
    *twitter.com*|*x.com*) print -r -- twitter ;;
    *youtube.com*|*youtu.be*) print -r -- youtube ;;
    *tiktok.com*) print -r -- tiktok ;;
    *vimeo.com*) print -r -- vimeo ;;
    *) print -r -- other ;;
  esac
}
