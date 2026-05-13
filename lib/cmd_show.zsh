# wisdom show — print one wisdom file (frontmatter + body) by id-prefix.

_wisdom_show() {
  local prefix="$1"
  if [[ -z "$prefix" ]]; then
    print -r -- "show: id required" >&2; return 1
  fi
  local repo
  repo=$(wisdom_repo_path) || return 2

  # Find candidates by filename prefix
  local -a matches
  matches=("$repo"/wisdoms/**/"${prefix}"*.md(N))
  if (( ${#matches} == 0 )); then
    print -r -- "show: no wisdom matches prefix '$prefix'" >&2
    return 1
  fi
  if (( ${#matches} > 1 )); then
    print -r -- "show: prefix '$prefix' matches multiple wisdoms:"
    local m id
    for m in $matches; do
      id="${${m:t}:r}"
      print -r -- "  $id"
    done
    return 1
  fi

  local f="${matches[1]}"
  local id ts cat tags src author note body
  id=$(awk -F': ' '/^id:/{print $2; exit}' "$f")
  ts=$(awk -F': ' '/^created_at:/{print $2; exit}' "$f")
  cat=$(awk -F': ' '/^category:/{print $2; exit}' "$f")
  tags=$(awk -F': ' '/^tags:/{print $2; exit}' "$f")
  src=$(awk -F': ' '/^source_url:/{print $2; exit}' "$f")
  author=$(awk -F': ' '/^source_author:/{print $2; exit}' "$f")
  note=$(awk -F': ' '/^note:/{print $2; exit}' "$f")
  body=$(awk '/^---$/{n++; next} n==2{print}' "$f")

  print -r -- "id:           $id"
  print -r -- "created_at:   $ts"
  print -r -- "category:     $cat"
  print -r -- "tags:         $tags"
  [[ "$src"    != "null" ]] && print -r -- "source_url:   $src"
  [[ "$author" != "null" ]] && print -r -- "source_author:$author"
  [[ "$note"   != '""'   && -n "$note" ]] && print -r -- "note:         $note"
  print -r -- "---"
  print -r -- "$body"
}
