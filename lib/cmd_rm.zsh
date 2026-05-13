# wisdom rm — git rm a wisdom file by id-prefix, with confirm prompt.

_wisdom_rm() {
  local prefix="" yes=0
  while (( $# )); do
    case "$1" in
      -y|--yes) yes=1; shift ;;
      -*) print -r -- "rm: unknown flag $1" >&2; return 1 ;;
      *)
        if [[ -z "$prefix" ]]; then prefix="$1"; shift
        else print -r -- "rm: unexpected arg $1" >&2; return 1; fi ;;
    esac
  done
  [[ -z "$prefix" ]] && { print -r -- "rm: id required" >&2; return 1; }

  local repo
  repo=$(wisdom_repo_path) || return 2
  local -a matches=("$repo"/wisdoms/**/"${prefix}"*.md(N))
  if (( ${#matches} == 0 )); then
    print -r -- "rm: no wisdom matches '$prefix'" >&2; return 1
  fi
  if (( ${#matches} > 1 )); then
    print -r -- "rm: prefix matches multiple wisdoms:"
    print -rl -- ${matches:t:r}
    return 1
  fi
  local f="${matches[1]}"

  local id body body_short
  id=$(awk -F': ' '/^id:/{print $2; exit}' "$f")
  body=$(awk '/^---$/{n++; next} n==2{print}' "$f")
  body_short=$(print -r -- "$body" | tr -s '[:space:]' ' ' | sed -E 's/^ +//; s/ +$//' | cut -c1-60)

  if (( ! yes )); then
    print -r -- "Remove $id?"
    print -r -- "  $body_short…"
    print -n -- "Confirm (y/N)? "
    local reply
    read -r reply
    [[ "$reply" == [yY]* ]] || { print -r -- "cancelled"; return 0; }
  fi

  (
    cd "$repo"
    git rm -q "${f#$repo/}"
    git commit -q -m "wisdom: remove ${id:0:6} — ${body_short}…"
  )
  print -r -- "removed $id"
}
