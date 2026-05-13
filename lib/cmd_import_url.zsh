# wisdom import-url — ingest one or more URLs through the 3-layer pipeline.

# Load helpers (idempotent in case parent already sourced them).
_wisdom_import_url_dir=${0:A:h}
[[ -z "${functions[wisdom_url_hash]:-}" ]] && source "${_wisdom_import_url_dir}/_url_helpers.zsh"

_wisdom_import_url() {
  local engine="${WISDOM_ENGINE:-claude}"
  local -a urls
  while (( $# )); do
    case "$1" in
      --engine) engine="$2"; shift 2 ;;
      --engine=*) engine="${1#--engine=}"; shift ;;
      -*) print -r -- "import-url: unknown flag $1" >&2; return 1 ;;
      *) urls+=("$1"); shift ;;
    esac
  done
  (( ${#urls} == 0 )) && { print -r -- "import-url: at least one URL required" >&2; return 1; }

  local url
  for url in $urls; do
    _wisdom_import_url_one "$url" "$engine" || {
      print -r -- "import-url: failed for $url (continuing with remaining URLs)" >&2
    }
  done
}

# Process one URL: scrape, build preview bundle, launch agent for extraction.
_wisdom_import_url_one() {
  local url="$1" engine="$2"
  print -r -- "import-url: $url"

  # Re-import dedup check (real impl in C17)
  if _wisdom_url_check_reimport "$url"; then
    return 0
  fi

  local cache
  cache=$(wisdom_url_cache_dir "$url")

  # Layer 1: yt-dlp scrape
  if _wisdom_url_scrape_ytdlp "$url" "$cache"; then
    :
  else
    # Layer 2: Playwright MCP / agent fallback
    if ! _wisdom_url_scrape_playwright "$url" "$cache"; then
      # Layer 3: manual fallback
      _wisdom_url_manual_fallback "$url" "$cache" || return 7
    fi
  fi

  # Whisper transcription if audio exists
  if [[ -f "$cache/audio.mp3" || -f "$cache/audio.m4a" || -f "$cache/audio.wav" ]]; then
    _wisdom_url_transcribe "$cache" || true
  fi

  # ffmpeg keyframes if video exists
  if [[ -f "$cache/video.mp4" ]]; then
    _wisdom_url_keyframes "$cache" || true
  fi

  # Comments scrape (IG only)
  case "$(wisdom_url_domain "$url")" in
    instagram) _wisdom_url_scrape_comments "$url" "$cache" || true ;;
  esac

  # Hand off to agent session for extraction
  _wisdom_url_launch_extraction "$url" "$cache" "$engine"
}

# Stubs — replaced in subsequent tasks.
_wisdom_url_check_reimport()    { return 1 ; }
_wisdom_url_scrape_ytdlp()      { print -r -- "  [stub] yt-dlp not implemented yet"; return 1 ; }
_wisdom_url_scrape_playwright() { print -r -- "  [stub] playwright fallback not implemented yet"; return 1 ; }
_wisdom_url_manual_fallback()   { print -r -- "  [stub] manual fallback not implemented yet"; return 1 ; }
_wisdom_url_transcribe()        { return 0 ; }
_wisdom_url_keyframes()         { return 0 ; }
_wisdom_url_scrape_comments()   { return 0 ; }
_wisdom_url_launch_extraction() { print -r -- "  [stub] extraction launch not implemented yet"; return 0 ; }
