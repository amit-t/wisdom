#!/usr/bin/env zsh
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/cmd_capture.zsh"

# Mock the engine launcher so tests don't actually open Claude
_wisdom_launch_engine() {
  # Print the captured snippet + engine to stdout so the test can inspect.
  local engine="$1"; shift
  local snippet="$1"
  print -r -- "ENGINE=$engine"
  print -r -- "SNIPPET=$snippet"
  return 0
}

# Mode 1: positional arg
out=$(_wisdom_capture "Programming is not about typing." 2>&1)
assert_contains "$out" "ENGINE=claude" "default engine"
assert_contains "$out" "Programming is not about typing." "positional snippet"

# Mode 2: stdin (`-`)
out=$(print -r -- "from stdin always works" | _wisdom_capture - 2>&1)
assert_contains "$out" "from stdin" "stdin mode"

# Mode 3: engine flag
out=$(_wisdom_capture --engine codex "codex one-shot test wisdom snippet" 2>&1)
assert_contains "$out" "ENGINE=codex" "engine flag"

# Mode 4: WISDOM_ENGINE env
out=$(WISDOM_ENGINE=devin _wisdom_capture "via env this snippet is long enough" 2>&1)
assert_contains "$out" "ENGINE=devin" "env override"

# Mode 5: no args -> pure launcher (empty snippet)
out=$(_wisdom_capture 2>&1)
assert_contains "$out" "SNIPPET=" "pure launcher"

# Mode 6: length guard rejects too-short positional
_wisdom_capture "ok" >/tmp/wis-out 2>&1
rc=$?
assert_exit_code 6 $rc "length guard rejects short snippet"
