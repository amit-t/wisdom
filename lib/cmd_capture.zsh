# Capture command: dispatcher for input modes + engine launcher.

# Edit-template used when `-e` is passed.
_WISDOM_EDIT_TEMPLATE='# Paste or type your wisdom below this line. Lines starting with `#` are ignored.
# When done, save and exit. Empty -> cancel.

'

# Real engine launcher; can be overridden in tests.
_wisdom_launch_engine() {
  local engine="$1"; shift
  local snippet="$1"
  local repo
  repo=$(wisdom_repo_path) || return 2
  cd "$repo" || return 2

  case "$engine" in
    claude)
      if (( $+commands[claude] )); then
        if [[ -n "$snippet" ]]; then
          # Pre-feed the snippet as first user turn, skill auto-engages from AGENTS.md.
          print -r -- "Record this wisdom snippet:\n\n$snippet" | claude
        else
          claude
        fi
      else
        print -r -- "wisdom: 'claude' CLI not found on \$PATH" >&2
        return 3
      fi
      ;;
    codex)
      if (( $+commands[codex] )); then
        if [[ -n "$snippet" ]]; then
          print -r -- "Record this wisdom snippet:\n\n$snippet" | codex
        else
          codex
        fi
      else
        print -r -- "wisdom: 'codex' CLI not found on \$PATH" >&2
        return 3
      fi
      ;;
    devin)
      if (( $+commands[devin] )); then
        if [[ -n "$snippet" ]]; then
          devin --task "Record this wisdom snippet:\n\n$snippet"
        else
          devin
        fi
      else
        print -r -- "wisdom: 'devin' CLI not found on \$PATH" >&2
        return 3
      fi
      ;;
    *)
      print -r -- "wisdom: unknown engine '$engine' (use claude|codex|devin)" >&2
      return 1
      ;;
  esac
}

_wisdom_capture() {
  local engine="${WISDOM_ENGINE:-claude}"
  local snippet=""
  local use_editor=0
  local from_stdin=0

  # Parse args
  while (( $# )); do
    case "$1" in
      --engine)
        engine="$2"; shift 2 ;;
      --engine=*)
        engine="${1#--engine=}"; shift ;;
      -e)
        use_editor=1; shift ;;
      -)
        from_stdin=1; shift ;;
      --)
        shift; break ;;
      -*)
        print -r -- "wisdom capture: unknown flag $1" >&2; return 1 ;;
      *)
        # Positional snippet (joined by spaces if multiple)
        if [[ -z "$snippet" ]]; then snippet="$1"; else snippet="$snippet $1"; fi
        shift ;;
    esac
  done

  # Resolve snippet source
  if (( from_stdin )); then
    snippet=$(cat)
  elif (( use_editor )); then
    local tmp
    tmp=$(mktemp -t wisdom-edit.XXXXXX.md)
    print -r -- "$_WISDOM_EDIT_TEMPLATE" > "$tmp"
    "${WISDOM_EDITOR:-${EDITOR:-vi}}" "$tmp"
    # Strip comment lines and trim
    snippet=$(grep -v '^#' "$tmp" | sed -E '/./,$!d' | sed -E ':a;$!N;$!ba;s/\n+$//')
    rm -f "$tmp"
  fi

  # Validate length if we have a snippet
  if [[ -n "$snippet" ]]; then
    wisdom_check_length "$snippet" || return $?
  fi

  _wisdom_launch_engine "$engine" "$snippet"
}
