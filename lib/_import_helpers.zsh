# Helpers shared across import formats.

# Write one wisdom file with the given fields. Echoes the path of the written
# file. Honors --no-categorize: when category is empty, defaults to 'life'.
wisdom_write_record() {
  local body="$1" source_url="$2" source_author="$3" note="$4" \
        category="$5" tags_csv="$6" origin="$7"
  [[ -z "$category" ]] && category="life"
  local repo id now year month dir tags_yaml
  repo=$(wisdom_repo_path) || return 2
  id=$(wisdom_ulid)
  now=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
  year=${now:0:4}
  month=${now:5:2}
  dir="$repo/wisdoms/$year/$month"
  mkdir -p "$dir"

  # Render tags as YAML flow list
  if [[ -z "$tags_csv" ]]; then
    tags_yaml='[]'
  else
    tags_yaml="[${tags_csv// , /, }]"
    tags_yaml="${tags_yaml// ,/,}"
  fi

  local hash
  hash=$(wisdom_body_hash "$body")

  local out="$dir/$id.md"
  {
    print -r -- "---"
    print -r -- "id: $id"
    print -r -- "created_at: $now"
    print -r -- "body_hash: $hash"
    print -r -- "category: $category"
    print -r -- "tags: $tags_yaml"
    print -r -- "source_url: ${source_url:-null}"
    print -r -- "source_author: ${source_author:-null}"
    print -r -- "note: \"${note}\""
    print -r -- "import_origin: ${origin:-manual}"
    print -r -- "---"
    print -r --
    print -r -- "$body"
  } > "$out"

  print -r -- "$out"
}
