---
layout: page
title: Search
eyebrow: SEARCH
description: Full-text search across the corpus, filterable by bucket and tag.
---

<div id="search"></div>

<noscript>
  <p>Search requires JavaScript. Browse by
    {% for cat in site.data.wisdoms.categories %}
      <a href="{{ '/buckets/' | append: cat.key | append: '/' | relative_url }}">{{ cat.label }}</a>{% unless forloop.last %}, {% endunless %}
    {% endfor %} instead.</p>
</noscript>

<link rel="stylesheet" href="{{ '/pagefind/pagefind-ui.css' | relative_url }}">
<script src="{{ '/pagefind/pagefind-ui.js' | relative_url }}"></script>
<script src="{{ '/assets/js/search.js' | relative_url }}"></script>
