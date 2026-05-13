---
layout: page
title: Engineering
eyebrow: ENGINEERING
bucket: engineering
permalink: /buckets/engineering/
---

{% assign wisdoms_in_bucket = site.wisdoms | where: "category", page.bucket | sort: "created_at" | reverse %}

{% if wisdoms_in_bucket.size == 0 %}
  <p class="empty-state">No wisdoms in this bucket yet.</p>
{% else %}
  <p class="bucket-count">{{ wisdoms_in_bucket.size }} wisdom{% if wisdoms_in_bucket.size != 1 %}s{% endif %}</p>
  <div class="wisdom-list">
    {% for w in wisdoms_in_bucket %}
      {% include wisdom-card.html wisdom=w %}
    {% endfor %}
  </div>
{% endif %}
