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
_wisdom_url_scrape_ytdlp() {
  local url="$1" cache="$2"
  if ! (( $+commands[yt-dlp] )); then
    print -r -- "  yt-dlp not on \$PATH (brew install yt-dlp)" >&2
    return 1
  fi

  # Metadata
  if ! yt-dlp \
      --no-warnings \
      --dump-single-json \
      --skip-download \
      -o "$cache/%(id)s" \
      "$url" > "$cache/meta.json" 2>"$cache/yt-dlp-meta.err"; then
    print -r -- "  yt-dlp metadata fetch failed; see $cache/yt-dlp-meta.err" >&2
    return 1
  fi

  # Thumbnail
  yt-dlp \
      --no-warnings \
      --skip-download \
      --write-thumbnail \
      -o "$cache/thumb.%(ext)s" \
      "$url" >/dev/null 2>"$cache/yt-dlp-thumb.err" || true

  # Audio (mp3 preferred)
  yt-dlp \
      --no-warnings \
      -x --audio-format mp3 --audio-quality 5 \
      -o "$cache/audio.%(ext)s" \
      "$url" >/dev/null 2>"$cache/yt-dlp-audio.err" || true

  return 0
}
_wisdom_url_scrape_playwright() { print -r -- "  [stub] playwright fallback not implemented yet"; return 1 ; }
_wisdom_url_manual_fallback()   { print -r -- "  [stub] manual fallback not implemented yet"; return 1 ; }
_wisdom_url_transcribe() {
  local cache="$1"
  local audio="" ext
  for ext in mp3 m4a wav; do
    [[ -f "$cache/audio.$ext" ]] && { audio="$cache/audio.$ext"; break; }
  done
  [[ -z "$audio" ]] && return 0

  local out="$cache/transcript.txt"
  local mode="${WISDOM_WHISPER:-local}"
  case "$mode" in
    local) _wisdom_whisper_local "$audio" "$out" ;;
    api)   _wisdom_whisper_api   "$audio" "$out" ;;
    *)
      print -r -- "  whisper: unknown mode '$mode' (use local|api)" >&2
      return 1 ;;
  esac
}

# Default implementations. Either may be overridden in tests.
_wisdom_whisper_local() {
  local audio="$1" out="$2"
  if ! (( $+commands[whisper] || $+commands[whisper-cpp] )); then
    print -r -- "  whisper.cpp not on \$PATH (brew install whisper-cpp); skipping transcription" >&2
    return 0
  fi
  if (( $+commands[whisper-cpp] )); then
    whisper-cpp -f "$audio" -otxt -of "${out:r}" >/dev/null 2>&1 || true
  else
    whisper "$audio" --model base --output_format txt --output_dir "${out:h}" >/dev/null 2>&1 || true
    local stem="${audio:t:r}"
    [[ -f "${out:h}/${stem}.txt" ]] && mv "${out:h}/${stem}.txt" "$out"
  fi
}

_wisdom_whisper_api() {
  local audio="$1" out="$2"
  if [[ -z "${OPENAI_API_KEY:-}" ]]; then
    print -r -- "  whisper api: OPENAI_API_KEY not set; skipping" >&2
    return 0
  fi
  curl -sS https://api.openai.com/v1/audio/transcriptions \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: multipart/form-data" \
    -F file="@$audio" \
    -F model="whisper-1" \
    -F response_format="text" \
    > "$out"
}
_wisdom_url_keyframes()         { return 0 ; }
_wisdom_url_scrape_comments()   { return 0 ; }
_wisdom_url_launch_extraction() { print -r -- "  [stub] extraction launch not implemented yet"; return 0 ; }
