---
layout: page
title: About
eyebrow: ABOUT
---

This site is a personal collection of wisdom — quotes, observations, and small
arguments worth remembering. It is built from one Markdown file per snippet,
each filed under a closed set of buckets and tagged for cross-cutting concerns.

## Buckets

{% for cat in site.data.wisdoms.categories %}
- **<span class="eyebrow-{{ cat.color }}">{{ cat.label }}</span>** — {{ cat.description }}
{% endfor %}

## How snippets land here

Each snippet is captured via a CLI (`wisdom "..."`) or by typing `/wisdom`
(Claude / Devin) or `$wisdom` (Codex) inside an agent session. An LLM
categorizes the snippet into one of the buckets above, with the option to
propose a new bucket if no existing one fits. The snippet is saved as a
Markdown file with structured frontmatter, then committed and (optionally)
pushed. This site rebuilds automatically on push.

## Search

The [search page](/search/) uses [Pagefind](https://pagefind.app/) — a
client-side full-text search index built from the rendered HTML at deploy
time. Filter by bucket or tag using the filters below the query box.

## Source

The repository, including the CLI, the skill, and the entire corpus, lives at
<https://github.com/amit-t/wisdom>.

## License

Code is MIT; the corpus itself is CC BY 4.0. See `LICENSE` in the repo.
