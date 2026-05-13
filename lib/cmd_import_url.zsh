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

  # Scrape phase — parallel for >1 URL
  if (( ${#urls} > 1 )); then
    print -r -- "import-url: scraping ${#urls} URLs in parallel..."
    local url
    local -a pids
    for url in $urls; do
      ( _wisdom_url_scrape_only "$url" ) &
      pids+=($!)
    done
    local pid
    for pid in $pids; do wait "$pid"; done
  fi

  # Extract phase — sequential (each opens an agent session)
  local url
  for url in $urls; do
    _wisdom_import_url_one "$url" "$engine" || \
      print -r -- "import-url: failed for $url (continuing)" >&2
  done
}

# Scrape-only: runs everything except the agent extraction launch.
_wisdom_url_scrape_only() {
  local url="$1" cache
  cache=$(wisdom_url_cache_dir "$url")
  if _wisdom_url_check_reimport "$url"; then return 0; fi
  if ! _wisdom_url_scrape_ytdlp "$url" "$cache"; then
    _wisdom_url_scrape_playwright "$url" "$cache" || _wisdom_url_manual_fallback "$url" "$cache" || true
  fi
  [[ -f "$cache/audio.mp3" || -f "$cache/audio.m4a" || -f "$cache/audio.wav" ]] && _wisdom_url_transcribe "$cache" || true
  [[ -f "$cache/video.mp4" ]] && _wisdom_url_keyframes "$cache" || true
  case "$(wisdom_url_domain "$url")" in
    instagram) _wisdom_url_scrape_comments "$url" "$cache" || true ;;
  esac
}

# Process one URL: ensure cache populated, then launch extraction.
_wisdom_import_url_one() {
  local url="$1" engine="$2"
  print -r -- "import-url: extract for $url"
  local cache
  cache=$(wisdom_url_cache_dir "$url")
  # If the cache is empty (single-URL invocation skipped the pre-step), run
  # the scrape inline now.
  if [[ ! -e "$cache/meta.json" && ! -f "$cache/manual-paste.txt" && ! -f "$cache/agent-directive.md" ]]; then
    _wisdom_url_scrape_only "$url"
  fi
  _wisdom_url_launch_extraction "$url" "$cache" "$engine"
}

# Stubs — replaced in subsequent tasks.
_wisdom_url_check_reimport() {
  local url="$1" repo
  repo=$(wisdom_repo_path) || return 1
  [[ -d "$repo/wisdoms" ]] || return 1

  local hit
  hit=$(grep -rl -F "source_url: $url" "$repo/wisdoms" 2>/dev/null | head -n 1)
  if [[ -z "$hit" ]]; then
    # Also check import_origin since URLs without trailing slashes could differ
    hit=$(grep -rl -F "import_origin: url:$url" "$repo/wisdoms" 2>/dev/null | head -n 1)
  fi
  [[ -z "$hit" ]] && return 1

  local id body_preview
  id=$(awk -F': ' '/^id:/{print $2; exit}' "$hit")
  body_preview=$(awk '/^---$/{n++; next} n==2 && NF{print; exit}' "$hit" | cut -c1-80)

  print -r -- "  URL already imported as $id:"
  print -r -- "    $body_preview"

  local choice="${WISDOM_REIMPORT_DEFAULT:-}"
  if [[ -z "$choice" ]]; then
    print -n -- "    [v]iew / [u]pdate-note / [n]ew-extract / [c]ancel (default: c): "
    read -r choice
    [[ -z "$choice" ]] && choice=c
  fi
  case "${choice:0:1}" in
    v) _wisdom_show "$id" ; return 0 ;;
    u) print -r -- "    update-note: not yet wired; cancelled (use \`wisdom edit $id\`)" >&2; return 0 ;;
    n) print -r -- "    proceeding with new extraction from same URL" ; return 1 ;;
    s) print -r -- "    skipped (already imported)" ; return 0 ;;
    c|*) print -r -- "    cancelled" ; return 0 ;;
  esac
}
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
_wisdom_url_scrape_playwright() {
  local url="$1" cache="$2"
  print -r -- "  yt-dlp failed; will request agent to scrape via Playwright MCP if available."
  # Write a directive file the agent reads in the extraction step.
  cat > "$cache/agent-directive.md" <<EOF
# Scraping directive for the agent

The yt-dlp layer failed for this URL:

  $url

If you have a Playwright MCP server registered (e.g.,
\`@playwright/mcp\` or \`chrome-devtools-mcp\`) AND a logged-in browser
profile on this machine that can see this URL, use it to:

1. Navigate to the URL using the user's existing browser profile (NOT a
   headless session — IG aggressively blocks those).
2. Extract:
   - The page title or post caption to \`$cache/caption.txt\`
   - Any visible body text to \`$cache/page-text.txt\`
   - Up to 3 of the top user comments (Instagram only) to
     \`$cache/comments.txt\`
   - The cover image to \`$cache/thumb.jpg\` if not already present
3. If the page has a video, capture the audio stream (if MCP supports it) to
   \`$cache/audio.mp3\` and request that the Whisper step run on it.

If no Playwright MCP is registered OR the scrape fails, fall through to the
manual-fallback flow:

- Open the URL in the user's default browser:
  \`open "$url"\` (macOS) / \`xdg-open "$url"\` (Linux)
- Ask the user to paste the caption / quote / transcript directly into the
  chat, then proceed with the normal Capture flow using that text.
EOF
  # Indicate to the caller that "scraping" succeeded in the sense that there's
  # a directive for the agent. The agent decides whether MCP path is usable.
  return 0
}
_wisdom_url_manual_fallback() {
  local url="$1" cache="$2"
  print -r -- "  manual fallback: opening URL in browser..."
  if (( $+commands[open] )); then
    open "$url" >/dev/null 2>&1 || true
  elif (( $+commands[xdg-open] )); then
    xdg-open "$url" >/dev/null 2>&1 || true
  fi
  print -r -- "  paste the caption / quote / transcript when ready."
  print -r -- "  end input with Ctrl-D on its own line."
  local pasted
  pasted=$(cat)
  if [[ -z "${pasted//[[:space:]]/}" ]]; then
    print -r -- "  empty input; aborting." >&2
    return 7
  fi
  print -r -- "$pasted" > "$cache/manual-paste.txt"
  return 0
}
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
_wisdom_url_keyframes() {
  local cache="$1"
  [[ -f "$cache/video.mp4" ]] || return 0
  if ! (( $+commands[ffmpeg] )); then
    print -r -- "  ffmpeg not on \$PATH (brew install ffmpeg); skipping keyframes" >&2
    return 0
  fi
  mkdir -p "$cache/keyframes"
  # One frame every 5 seconds; up to 12 frames max
  ffmpeg -y -i "$cache/video.mp4" \
    -vf "fps=1/5,scale=720:-2" \
    -frames:v 12 \
    "$cache/keyframes/frame-%03d.jpg" \
    >/dev/null 2>&1 || true
}
_wisdom_url_scrape_comments() {
  local url="$1" cache="$2"
  if ! (( $+commands[yt-dlp] )); then
    return 0
  fi
  # Try yt-dlp first
  if yt-dlp \
      --no-warnings \
      --skip-download \
      --write-comments \
      -o "$cache/_comments" \
      "$url" >/dev/null 2>"$cache/yt-dlp-comments.err"; then
    # Take top 5 comments by like count
    if [[ -f "$cache/_comments.info.json" ]]; then
      jq -r '
        (.comments // [])
        | sort_by(-(.like_count // 0))
        | .[0:5]
        | map("- @" + (.author // "?") + ": " + ((.text // "") | gsub("\n"; " ")))
        | .[]
      ' "$cache/_comments.info.json" > "$cache/comments.txt"
    fi
  fi

  # Augment with Playwright directive if no comments file was produced
  if [[ ! -s "$cache/comments.txt" ]]; then
    cat >> "$cache/agent-directive.md" 2>/dev/null <<EOF

# Comments scrape directive

yt-dlp did not produce comments for this Instagram URL. If you have a
Playwright MCP path available, scrape the top 5 comments from the post and
write them to \`$cache/comments.txt\`, one per line, prefixed with the
commenter handle, e.g. \`- @handle: comment text\`.
EOF
  fi
  return 0
}
_wisdom_url_launch_extraction() {
  local url="$1" cache="$2" engine="$3"

  # Assemble a preview prompt for the agent.
  local prompt_file="$cache/prompt.txt"
  {
    print -r -- "Record a wisdom snippet derived from this URL:"
    print -r --
    print -r -- "URL: $url"
    print -r --
    if [[ -f "$cache/meta.json" ]]; then
      print -r -- "## Metadata (yt-dlp)"
      print -r -- '```json'
      jq '{title, uploader, channel, description, duration, upload_date, view_count, like_count}' "$cache/meta.json" 2>/dev/null
      print -r -- '```'
      print -r --
    fi
    if [[ -f "$cache/caption.txt" ]]; then
      print -r -- "## Caption (Playwright)"
      print -r -- "$(cat "$cache/caption.txt")"; print -r --
    fi
    if [[ -f "$cache/manual-paste.txt" ]]; then
      print -r -- "## User-pasted content"
      print -r -- "$(cat "$cache/manual-paste.txt")"; print -r --
    fi
    if [[ -f "$cache/transcript.txt" ]]; then
      print -r -- "## Transcript (Whisper)"
      print -r -- "$(cat "$cache/transcript.txt")"; print -r --
    fi
    if [[ -f "$cache/comments.txt" ]]; then
      print -r -- "## Top comments"
      cat "$cache/comments.txt"; print -r --
    fi
    if [[ -d "$cache/keyframes" ]]; then
      print -r -- "## Keyframes available at"
      print -r -- "$cache/keyframes/"
      print -r --
    fi
    local t="" ext
    for ext in jpg png webp; do
      [[ -f "$cache/thumb.$ext" ]] && t="$cache/thumb.$ext"
    done
    if [[ -n "$t" ]]; then
      print -r -- "## Cover image"
      print -r -- "$t"; print -r --
    fi
    if [[ -f "$cache/agent-directive.md" ]]; then
      print -r --
      print -r -- "## Scraping directive"
      cat "$cache/agent-directive.md"
    fi
    print -r --
    print -r -- "Follow the wisdom-capture skill. Use the metadata above plus any"
    print -r -- "images in the keyframes/cover paths to extract the actual wisdom"
    print -r -- "body (vision OK — read the images). source_url MUST be the URL"
    print -r -- "above. import_origin MUST be \"url:$url\"."
  } > "$prompt_file"

  # Hand off to the existing capture launcher with the prompt as snippet.
  local snippet
  snippet=$(<"$prompt_file")
  _wisdom_launch_engine "$engine" "$snippet"
}
