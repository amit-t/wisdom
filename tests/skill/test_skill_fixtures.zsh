#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"

if (( ! $+commands[claude] )); then
  print -r -- "SKIP: 'claude' CLI not on \$PATH"
  exit 0
fi

fixtures_dir="$repo_root/.agents/skills/wisdom-capture/examples"
skill_path="$repo_root/.agents/skills/wisdom-capture/SKILL.md"

# We don't really need to run the whole capture flow; we just want to confirm
# the model, given the SKILL.md context, picks the same primary category as
# the fixture's expected output.

check_fixture() {
  local fixture="$1"
  local expected_primary="$2"
  local input
  input=$(awk '/^## Input/{f=1; next} /^## Expected/{f=0} f && /^```$/{next} f && /^```/{next} f' "$fixture")

  # Compose prompt: include the skill + the fixture input + a request for the
  # primary key only.
  local prompt
  prompt=$(cat <<EOF
You have the following SKILL.md as context:

$(cat "$skill_path")

The user provides this wisdom snippet:

$input

Read wisdoms/_categories.yml in this repo and decide the primary category key
from {engineering, leadership, writing, product, craft, life}. Reply with the
key only, lowercase, no other text.
EOF
)

  local got
  got=$(print -r -- "$prompt" | claude -p 2>/dev/null | tr -d '[:space:]')

  if [[ "$got" == "$expected_primary" ]]; then
    return 0
  else
    print -r -- "  fixture: ${fixture:t}"
    print -r -- "  expected primary: $expected_primary"
    print -r -- "  got:              $got"
    return 1
  fi
}

# Allow soft failure for the ambiguous fixture: writing or leadership both OK.
check_fixture "$fixtures_dir/high-conf-eng.md" engineering || exit 1
check_fixture "$fixtures_dir/no-fit-new-bucket.md" life || \
  check_fixture "$fixtures_dir/no-fit-new-bucket.md" investing || exit 1

# Ambiguous: accept writing OR leadership
got=$(check_fixture "$fixtures_dir/ambiguous.md" writing 2>&1 && echo writing) || \
got=$(check_fixture "$fixtures_dir/ambiguous.md" leadership 2>&1 && echo leadership) || true
[[ "$got" == "writing" || "$got" == "leadership" ]] || {
  print -r -- "  ambiguous fixture: must land in writing or leadership"; exit 1
}
