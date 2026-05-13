# wisdom import — import wisdom from a file in one of several formats.
#
# Usage:
#   wisdom import <file>
#   wisdom import --format md|json|csv|txt|notion-export <file>
#   wisdom import --dry-run <file>
#   wisdom import --no-categorize <file>  # skip skill categorization (defaults to 'life')
#
# Format detection (when --format omitted):
#   *.md            -> md
#   *.json          -> json
#   *.csv           -> csv
#   *.txt           -> txt
#   *.zip           -> notion-export
#   default         -> md

# Load helpers (idempotent in case parent already sourced them).
_wisdom_import_helpers_dir=${0:A:h}
[[ -z "${functions[wisdom_write_record]:-}" ]] && source "${_wisdom_import_helpers_dir}/_import_helpers.zsh"

_wisdom_import() {
  local file="" fmt="" dry_run=0 no_cat=0
  while (( $# )); do
    case "$1" in
      --format) fmt="$2"; shift 2 ;;
      --format=*) fmt="${1#--format=}"; shift ;;
      --dry-run) dry_run=1; shift ;;
      --no-categorize) no_cat=1; shift ;;
      -*) print -r -- "import: unknown flag $1" >&2; return 1 ;;
      *)
        if [[ -z "$file" ]]; then file="$1"; shift
        else print -r -- "import: unexpected arg $1" >&2; return 1; fi ;;
    esac
  done
  [[ -z "$file" ]] && { print -r -- "import: file required" >&2; return 1; }
  [[ -f "$file" ]] || { print -r -- "import: no such file: $file" >&2; return 1; }

  if [[ -z "$fmt" ]]; then
    case "${file:e}" in
      md|markdown) fmt=md ;;
      json)        fmt=json ;;
      csv)         fmt=csv ;;
      txt)         fmt=txt ;;
      zip)         fmt=notion-export ;;
      *)           fmt=md ;;
    esac
  fi

  case "$fmt" in
    md)            _wisdom_import_md "$file" "$dry_run" "$no_cat" ;;
    json)          _wisdom_import_json "$file" "$dry_run" "$no_cat" ;;
    csv)           _wisdom_import_csv "$file" "$dry_run" "$no_cat" ;;
    txt)           _wisdom_import_txt "$file" "$dry_run" "$no_cat" ;;
    notion-export) _wisdom_import_notion "$file" "$dry_run" "$no_cat" ;;
    *) print -r -- "import: unknown format '$fmt'" >&2; return 1 ;;
  esac
}

# Markdown import: split on lines that are exactly `---`. Each chunk is one
# wisdom body.
_wisdom_import_md() {
  local file="$1" dry="$2" no_cat="$3"
  # Split content into chunks. Each chunk written to a tmp dir and read back.
  local tmpdir
  tmpdir=$(mktemp -d -t wisdom-md-split.XXXXXX)
  awk -v outdir="$tmpdir" '
    BEGIN { idx = 0; rec = "" }
    /^---$/ {
      if (rec != "") {
        f = sprintf("%s/chunk-%04d.txt", outdir, idx)
        print rec > f
        close(f)
        idx++
        rec = ""
      }
      next
    }
    {
      rec = (rec == "" ? $0 : rec "\n" $0)
    }
    END {
      if (rec != "") {
        f = sprintf("%s/chunk-%04d.txt", outdir, idx)
        print rec > f
        close(f)
      }
    }
  ' "$file"

  local -a chunk_files
  chunk_files=("$tmpdir"/chunk-*.txt(N))

  local -a clean
  local cf content trimmed
  for cf in $chunk_files; do
    content=$(<"$cf")
    trimmed="${content//[$'\n\t ']/}"
    [[ -n "$trimmed" ]] && clean+=("$content")
  done

  local n=${#clean}
  if (( dry )); then
    print -r -- "would import $n wisdom(s) from ${file:t}"
    local i=1
    for b in $clean; do
      local preview
      preview=$(print -r -- "$b" | tr -s '[:space:]' ' ' | sed -E 's/^ +//; s/ +$//' | cut -c1-80)
      print -r -- "  [$i] $preview"
      i=$((i + 1))
    done
    rm -rf "$tmpdir"
    return 0
  fi

  local repo
  repo=$(wisdom_repo_path) || return 2
  local written=0 outpath body_trimmed
  for b in $clean; do
    # Strip leading + trailing blank lines, preserve internal
    body_trimmed="$b"
    # Remove leading blank lines
    while [[ "$body_trimmed" == $'\n'* ]]; do
      body_trimmed="${body_trimmed#$'\n'}"
    done
    # Remove trailing blank lines
    while [[ "$body_trimmed" == *$'\n' ]]; do
      body_trimmed="${body_trimmed%$'\n'}"
    done
    outpath=$(wisdom_write_record "$body_trimmed" "" "" "" "" "" "file:${file:t}")
    written=$((written + 1))
  done

  rm -rf "$tmpdir"

  (
    cd "$repo"
    git add wisdoms/
    git commit -q -m "wisdom: import $written entries from ${file:t}"
  )
  print -r -- "imported $written entries; committed"
}

# Stubs for other formats — implemented in later tasks.
_wisdom_import_json() {
  local file="$1" dry="$2" no_cat="$3"
  if ! (( $+commands[jq] )); then
    print -r -- "import json: jq required (brew install jq)" >&2; return 1
  fi
  local n
  n=$(jq 'length' "$file" 2>/dev/null) || { print -r -- "import json: invalid JSON" >&2; return 1; }
  if (( dry )); then
    print -r -- "would import $n wisdom(s) from ${file:t}"
    jq -r '.[] | "  - " + (.body[0:80])' "$file"
    return 0
  fi

  local repo
  repo=$(wisdom_repo_path) || return 2
  local written=0 i body src author note category tags_csv
  for (( i=0; i<n; i++ )); do
    body=$(jq -r ".[$i].body // \"\"" "$file")
    [[ -z "$body" ]] && continue
    src=$(jq -r ".[$i].source_url // \"\"" "$file")
    author=$(jq -r ".[$i].source_author // \"\"" "$file")
    note=$(jq -r ".[$i].note // \"\"" "$file")
    category=$(jq -r ".[$i].category // \"\"" "$file")
    tags_csv=$(jq -r ".[$i].tags // [] | join(\", \")" "$file")
    wisdom_write_record "$body" "$src" "$author" "$note" "$category" "$tags_csv" "file:${file:t}" >/dev/null
    written=$((written + 1))
  done

  (cd "$repo" && git add wisdoms/ && git commit -q -m "wisdom: import $written entries from ${file:t}")
  print -r -- "imported $written entries; committed"
}
_wisdom_import_csv()    { print -r -- "import: csv not implemented yet"  >&2; return 1; }
_wisdom_import_txt()    { print -r -- "import: txt not implemented yet"  >&2; return 1; }
_wisdom_import_notion() { print -r -- "import: notion not implemented yet" >&2; return 1; }
