#!/usr/bin/env zsh
# Shared helpers for wisdom CLI. Functions are prefixed with `wisdom_`.

# Crockford base32 alphabet (lowercase, ULID spec).
_WISDOM_ULID_ALPHABET="0123456789abcdefghjkmnpqrstvwxyz"

# Generate a ULID (26 chars, lowercase Crockford base32).
# First 10 chars = 48-bit ms-precision timestamp; last 16 chars = 80-bit random.
wisdom_ulid() {
  local ms hex i v out=""
  # Milliseconds since epoch
  if command -v gdate >/dev/null 2>&1; then
    ms=$(gdate +%s%3N)
  else
    # macOS native date lacks %3N; synthesize
    local s ns
    s=$(date +%s)
    ns=$(date +%N 2>/dev/null)
    if [[ -z "$ns" || "$ns" == "N" ]]; then
      ms=$((s * 1000))
    else
      ms=$((s * 1000 + ${ns:0:3}))
    fi
  fi

  # 10-char timestamp portion: encode ms in base32, big-endian, 10 digits
  local t=$ms
  for i in {1..10}; do
    v=$(( t % 32 ))
    out="${_WISDOM_ULID_ALPHABET:$v:1}${out}"
    t=$(( t / 32 ))
  done

  # 16-char random portion: 10 random bytes -> base32 (only need 80 bits)
  hex=$(head -c 10 /dev/urandom | od -An -tx1 | tr -d ' \n')
  # Convert each pair of hex (8 bits) into base32; we need 16 base32 chars from 80 bits
  # Read bits MSB-first
  local bits="" b
  for (( i=0; i<${#hex}; i+=2 )); do
    b=$(printf '%08d' "$(echo "obase=2; ibase=16; ${(U)hex[$((i+1)),$((i+2))]}" | bc)")
    bits+="$b"
  done
  local r=""
  for (( i=0; i<80; i+=5 )); do
    v=$(( 2#${bits:$i:5} ))
    r+="${_WISDOM_ULID_ALPHABET:$v:1}"
  done

  print -r -- "${out}${r}"
}

# Normalize a body for hashing:
# 1. trim leading/trailing whitespace
# 2. collapse all whitespace runs to a single space
# 3. lowercase
wisdom_body_normalize() {
  local s="$1"
  # tr collapses all whitespace classes to one space; sed trims ends.
  print -r -- "$s" \
    | tr -s '[:space:]' ' ' \
    | sed -E 's/^ +//; s/ +$//' \
    | tr '[:upper:]' '[:lower:]'
}

# Compute sha256 hex of the normalized body.
wisdom_body_hash() {
  local s="$1"
  local norm
  norm=$(wisdom_body_normalize "$s")
  # macOS: `shasum -a 256`. Linux fallback: `sha256sum`.
  if (( $+commands[shasum] )); then
    print -r -- "$norm" | shasum -a 256 | awk '{print $1}'
  else
    print -r -- "$norm" | sha256sum | awk '{print $1}'
  fi
}

# Default repo location (overridable by WISDOM_REPO env).
_WISDOM_DEFAULT_REPO="${HOME}/Projects/AmitTiwari/wisdom"

# Resolve repo path. Prints to stdout, exits 2 if neither env nor default is a
# git repo on the filesystem (only checked when STRICT=1).
wisdom_repo_path() {
  local strict="${WISDOM_REPO_STRICT:-0}"
  local p="${WISDOM_REPO:-$_WISDOM_DEFAULT_REPO}"
  if [[ "$strict" == "1" && ! -d "$p/.git" ]]; then
    print -r -- "wisdom: repo not found at $p (set WISDOM_REPO)" >&2
    return 2
  fi
  print -r -- "$p"
}

# cd into the repo. Used by subcommands before any git op.
wisdom_cd_repo() {
  local p
  p=$(WISDOM_REPO_STRICT=1 wisdom_repo_path) || return $?
  cd "$p" || return 2
}

_WISDOM_LEN_MIN=20
_WISDOM_LEN_MAX=5000

# Check body length. Exits 6 if under min. Warns to stderr if over max but
# returns 0.
wisdom_check_length() {
  local body="$1"
  local n=${#body}
  if (( n < _WISDOM_LEN_MIN )); then
    print -r -- "wisdom: snippet too short ($n chars; min $_WISDOM_LEN_MIN)" >&2
    return 6
  fi
  if (( n > _WISDOM_LEN_MAX )); then
    print -r -- "wisdom: this looks long ($n chars; soft max $_WISDOM_LEN_MAX). Storing anyway." >&2
  fi
  return 0
}

# Search wisdoms/ for any file containing the given normalized-body hash.
# Args: $1 = body text, $2 = optional repo override
# Prints matching file path(s) on stdout (newline-separated), empty if none.
wisdom_find_dup() {
  local body="$1"
  local repo="${2:-$(wisdom_repo_path)}"
  local hash
  hash=$(wisdom_body_hash "$body")
  [[ -d "$repo/wisdoms" ]] || return 0
  # Match the frontmatter line exactly, avoiding false hits in body.
  grep -rl -E "^body_hash: ${hash}\$" "$repo/wisdoms" 2>/dev/null || true
}
