# Capture command: dispatcher for input modes + engine launcher.

# Edit-template used when `-e` is passed.
_WISDOM_EDIT_TEMPLATE='# Paste or type your wisdom below this line. Lines starting with `#` are ignored.
# When done, save and exit. Empty -> cancel.

'

# Kickoff prompt sent as the first user turn when `wisdom` is launched with no
# snippet. Matches the wisdom-capture skill description so the agent auto-
# engages and prompts the user for the snippet instead of sitting idle.
_WISDOM_KICKOFF_PROMPT='I want to record a wisdom snippet. Engage the wisdom-capture skill and ask me to paste it.'

# Real engine launcher; can be overridden in tests.
_wisdom_launch_engine() {
  local engine="$1"; shift
  local snippet="$1"
  local repo
  repo=$(wisdom_repo_path) || return 2
  cd "$repo" || return 2

  # Pick the first-turn payload: real snippet if provided, else the kickoff
  # prompt that auto-engages the skill.
  local first_turn
  if [[ -n "$snippet" ]]; then
    first_turn="Record this wisdom snippet:\n\n$snippet"
  else
    first_turn="$_WISDOM_KICKOFF_PROMPT"
  fi

  case "$engine" in
    claude)
      if (( $+commands[claude] )); then
        print -r -- "$first_turn" | claude
      else
        print -r -- "wisdom: 'claude' CLI not found on \$PATH" >&2
        return 3
      fi
      ;;
    codex)
      if (( $+commands[codex] )); then
        print -r -- "$first_turn" | codex
      else
        print -r -- "wisdom: 'codex' CLI not found on \$PATH" >&2
        return 3
      fi
      ;;
    devin)
      if (( $+commands[devin] )); then
        devin --task "$first_turn"
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
