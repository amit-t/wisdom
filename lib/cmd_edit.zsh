# wisdom edit — open a wisdom file in $EDITOR, recompute body_hash + updated_at,
# commit. With --no-recat, do not re-trigger the categorizer skill.

_wisdom_edit() {
  local prefix="" no_recat=0
  while (( $# )); do
    case "$1" in
      --no-recat) no_recat=1; shift ;;
      -*) print -r -- "edit: unknown flag $1" >&2; return 1 ;;
      *)
        if [[ -z "$prefix" ]]; then prefix="$1"; shift
        else print -r -- "edit: unexpected arg $1" >&2; return 1; fi ;;
    esac
  done
  if [[ -z "$prefix" ]]; then print -r -- "edit: id required" >&2; return 1; fi

  local repo
  repo=$(wisdom_repo_path) || return 2

  local -a matches=("$repo"/wisdoms/**/"${prefix}"*.md(N))
  if (( ${#matches} == 0 )); then
    print -r -- "edit: no wisdom matches '$prefix'" >&2; return 1
  fi
  if (( ${#matches} > 1 )); then
    print -r -- "edit: prefix matches multiple wisdoms:"
    print -rl -- ${matches:t:r}
    return 1
  fi
  local f="${matches[1]}"

  "${WISDOM_EDITOR:-${EDITOR:-vi}}" "$f"

  # Recompute body_hash + updated_at
  local body new_hash now
  body=$(awk '/^---$/{n++; next} n==2{print}' "$f")
  new_hash=$(wisdom_body_hash "$body")
  now=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

  # Rewrite frontmatter: replace body_hash + insert/replace updated_at
  local tmp_out
  tmp_out=$(mktemp)
  awk -v h="$new_hash" -v u="$now" '
    BEGIN { in_fm = 0; updated_seen = 0 }
    /^---$/ {
      print
      if (in_fm == 1) {
        if (!updated_seen) print "updated_at: " u
      }
      in_fm = (in_fm == 0) ? 1 : 2
      next
    }
    in_fm == 1 && /^body_hash:/ { print "body_hash: " h; next }
    in_fm == 1 && /^updated_at:/ { print "updated_at: " u; updated_seen = 1; next }
    { print }
  ' "$f" > "$tmp_out"
  mv "$tmp_out" "$f"

  if (( ! no_recat )); then
    print -r -- "edit: --no-recat applied implicitly (re-categorization via skill TBD; re-run \`wisdom \"...\"\` if category should change)"
  fi

  # Commit
  local id body_short
  id=$(awk -F': ' '/^id:/{print $2; exit}' "$f")
  body_short=$(print -r -- "$body" | tr -s '[:space:]' ' ' | sed -E 's/^ +//; s/ +$//' | cut -c1-60)
  (
    cd "$repo"
    git add "${f#$repo/}"
    git commit -m "wisdom: edit ${id:0:6} — ${body_short}…"
  )
}
