---
layout: home
title: Wisdom
description: A searchable corpus of curated wisdom
hero_eyebrow: WISDOM
hero_title: Things worth remembering.
hero_desc: A personal corpus of snippets — from books, talks, threads, reels, and arguments at dinner — categorized and searchable.
hero_actions:
  - { label: "Search", href: "/search/", primary: true }
  - { label: "GitHub", href: "https://github.com/amit-t/wisdom", external: true }
---

<section class="container section">
  <h2 class="section-title">Buckets</h2>
  <div class="bucket-grid">
    {% for cat in site.data.wisdoms.categories %}
      {% include bucket-tile.html cat=cat %}
    {% endfor %}
  </div>
</section>

<section class="container section">
  <h2 class="section-title">Recent</h2>
  {% assign recent = site.wisdoms | sort: "created_at" | reverse %}
  {% if recent.size == 0 %}
    <p class="empty-state">No wisdoms yet. Capture one with <code>wisdom "your snippet"</code>.</p>
  {% else %}
    <div class="wisdom-list">
      {% for w in recent limit:10 %}
        {% include wisdom-card.html wisdom=w %}
      {% endfor %}
    </div>
  {% endif %}
</section>
