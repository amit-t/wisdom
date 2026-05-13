#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"

# Require ruby + bundler. Skip if not available (e.g., bare CI runner).
if ! (( $+commands[bundle] )); then
  print -r -- "SKIP: bundler not on \$PATH"
  exit 0
fi

cd "$repo_root"

# Stage fixtures into wisdoms/
mkdir -p wisdoms/2026/05
cp tests/site/fixtures/01jfixture001abcdefghjkmnpq.md wisdoms/2026/05/01jfixture001abcdefghjkmnpq.md
cp tests/site/fixtures/01jfixture002abcdefghjkmnpq.md wisdoms/2026/05/01jfixture002abcdefghjkmnpq.md
cp tests/site/fixtures/01jfixture003abcdefghjkmnpq.md wisdoms/2026/05/01jfixture003abcdefghjkmnpq.md

cleanup() {
  rm -f wisdoms/2026/05/01jfixture00{1,2,3}abcdefghjkmnpq.md
  rmdir wisdoms/2026/05 2>/dev/null || true
  rmdir wisdoms/2026 2>/dev/null || true
}
trap cleanup EXIT

# Install gems quietly
bundle install --path vendor/bundle --quiet >/dev/null 2>&1

# Build
bundle exec jekyll build 2>/tmp/wis-build.log
rc=$?
assert_exit_code 0 $rc "jekyll build must succeed"

# Pages that must exist
assert_file_exists _site/index.html
assert_file_exists _site/about/index.html
assert_file_exists _site/search/index.html
for b in engineering leadership writing product craft life; do
  assert_file_exists "_site/buckets/$b/index.html"
done

# Per-wisdom permalinks
assert_file_exists "_site/w/01jfixture001abcdefghjkmnpq/index.html"
assert_file_exists "_site/w/01jfixture002abcdefghjkmnpq/index.html"
assert_file_exists "_site/w/01jfixture003abcdefghjkmnpq/index.html"

# Tag pages generated
assert_file_exists "_site/tags/optimization/index.html"
assert_file_exists "_site/tags/decisions/index.html"
assert_file_exists "_site/tags/drafting/index.html"

# Home page mentions a fixture
home=$(<_site/index.html)
assert_contains "$home" "Premature optimization" "home recent list must include fixture 1"

# Bucket page mentions the right fixture
eng=$(<_site/buckets/engineering/index.html)
assert_contains "$eng" "Premature optimization" "engineering bucket must include fixture 1"

# Permalink page mentions fixture
p1=$(<"_site/w/01jfixture001abcdefghjkmnpq/index.html")
assert_contains "$p1" "Premature optimization" "fixture 1 permalink body"
assert_contains "$p1" "data-pagefind-body" "fixture 1 must have pagefind attrs"
assert_contains "$p1" "data-pagefind-filter=\"category:engineering\"" "fixture 1 pagefind filter"

print -r -- "site smoke test PASSED"
