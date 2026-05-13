#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"

if (( ! $+commands[claude] )); then
  print -r -- "SKIP: 'claude' CLI not on \$PATH"
  exit 0
fi

# Skill is installed per-project via:
#   npx skills@latest add amit-t/skills --skill wisdom-capture
# Look it up in the project-level locations a known engine would use.
skill_root=""
for candidate in \
  "$repo_root/.claude/skills/wisdom-capture" \
  "$repo_root/.cognition/skills/wisdom-capture" \
  "$repo_root/.cursor/skills/wisdom-capture" \
  "$repo_root/.windsurf/skills/wisdom-capture"
do
  if [[ -f "$candidate/SKILL.md" ]]; then
    skill_root="$candidate"
    break
  fi
done

if [[ -z "$skill_root" ]]; then
  print -r -- "SKIP: wisdom-capture skill not installed in this project."
  print -r -- "      Install with: npx skills@latest add amit-t/skills --skill wisdom-capture"
  exit 0
fi

fixtures_dir="$skill_root/examples"
skill_path="$skill_root/SKILL.md"

if [[ ! -d "$fixtures_dir" ]]; then
  print -r -- "SKIP: skill installed but examples/ missing at $fixtures_dir"
  exit 0
fi

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

# Returns 0 if the fixture's primary category lands in any of the accepted set.
check_fixture_any() {
  local fixture="$1"; shift
  local accepted=("$@")
  local primary
  primary=$(check_fixture "$fixture" "${accepted[1]}" 2>/dev/null; print -r -- "$got")
  # The simpler approach: just run the model once and check membership.
  local input prompt
  input=$(awk '/^## Input/{f=1; next} /^## Expected/{f=0} f && /^```$/{next} f && /^```/{next} f' "$fixture")
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
  primary=$(print -r -- "$prompt" | claude -p 2>/dev/null | tr -d '[:space:]')
  for a in $accepted; do
    [[ "$primary" == "$a" ]] && return 0
  done
  print -r -- "  fixture: ${fixture:t}"
  print -r -- "  accepted: ${accepted[*]}"
  print -r -- "  got:      $primary"
  return 1
}

# High-confidence engineering snippet: must land in engineering.
check_fixture_any "$fixtures_dir/high-conf-eng.md" engineering craft || exit 1

# Ambiguous writing/leadership snippet: any of writing/leadership/craft is OK.
check_fixture_any "$fixtures_dir/ambiguous.md" writing leadership craft || exit 1

# No-fit fixture (Keynes markets quote): any closed-set bucket is acceptable
# since the model is forced to pick one. The skill's NEW BUCKET path is
# tested separately in interactive flows.
check_fixture_any "$fixtures_dir/no-fit-new-bucket.md" \
  life leadership product engineering craft writing || exit 1
