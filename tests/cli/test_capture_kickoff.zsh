#!/usr/bin/env zsh
# Verify that bare `wisdom` (no snippet) still pre-feeds a kickoff prompt to
# the engine so the wisdom-capture skill auto-engages instead of the agent
# sitting idle in an interactive window.
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/cmd_capture.zsh"

# Shim every engine binary onto PATH so the real launcher resolves them.
# Each shim records its argv + stdin to a known file so we can inspect what
# the launcher actually sent.
shim_dir=$(mktemp -d -t wisdom-shim.XXXXXX)
trap "rm -rf '$shim_dir'" EXIT

for engine in claude codex devin; do
  cat > "$shim_dir/$engine" <<EOF
#!/usr/bin/env zsh
print -r -- "ARGV: \$*" > "$shim_dir/$engine.out"
print -r -- "STDIN:" >> "$shim_dir/$engine.out"
cat >> "$shim_dir/$engine.out"
EOF
  chmod +x "$shim_dir/$engine"
done

PATH="$shim_dir:$PATH"
# Rebuild zsh's command hash so $+commands[claude] sees the shim.
rehash

# Use a real temp repo so wisdom_repo_path resolves cleanly.
tmp_repo=$(mktemp -d -t wisdom-kickoff.XXXXXX)
mkdir -p "$tmp_repo/wisdoms"
cp "$repo_root/wisdoms/_categories.yml" "$tmp_repo/wisdoms/_categories.yml"
export WISDOM_REPO="$tmp_repo"

# claude — no snippet → kickoff prompt on stdin
_wisdom_launch_engine claude "" >/dev/null
out=$(<"$shim_dir/claude.out")
assert_contains "$out" "STDIN:" "claude shim must have been invoked"
assert_contains "$out" "wisdom-capture" "claude no-snippet stdin must mention wisdom-capture skill"
assert_contains "$out" "paste"        "claude no-snippet stdin must ask user to paste"

# claude — snippet → snippet on stdin, NOT kickoff prompt
rm -f "$shim_dir/claude.out"
_wisdom_launch_engine claude "Programming is not about typing, it is about thinking." >/dev/null
out=$(<"$shim_dir/claude.out")
assert_contains "$out" "Programming is not about typing" "claude snippet path forwards snippet"
if [[ "$out" == *"Engage the wisdom-capture skill"* ]]; then
  print -r -- "  FAIL: claude snippet path must NOT include kickoff prompt" >&2
  exit 1
fi

# codex — no snippet → kickoff prompt on stdin
_wisdom_launch_engine codex "" >/dev/null
out=$(<"$shim_dir/codex.out")
assert_contains "$out" "wisdom-capture" "codex no-snippet stdin must mention skill"

# devin — no snippet → kickoff prompt as --task argv (not stdin)
_wisdom_launch_engine devin "" >/dev/null
out=$(<"$shim_dir/devin.out")
assert_contains "$out" "ARGV: --task" "devin must be invoked with --task"
assert_contains "$out" "wisdom-capture" "devin --task arg must mention skill"

rm -rf "$tmp_repo"
