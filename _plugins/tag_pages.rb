# _plugins/tag_pages.rb
# Generates /tags/<tag>/ index pages from the union of all wisdom tags.

module Jekyll
  class TagPage < Page
    def initialize(site, base, dir, tag, tagged)
      @site = site
      @base = base
      @dir  = dir
      @name = 'index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'page.html') if File.exist?(File.join(base, '_layouts', 'page.html'))
      self.data['layout']  = 'page'
      self.data['title']   = "##{tag}"
      self.data['eyebrow'] = 'TAG'
      self.data['description'] = "Wisdoms tagged ##{tag}."
      self.data['tag']     = tag
      self.data['tagged']  = tagged.map(&:url)
      self.content = <<~'LIQUID'
        {% assign tag = page.tag %}
        {% assign wisdoms_tagged = site.wisdoms | where_exp: "w", "w.tags contains tag" | sort: "created_at" | reverse %}

        {% if wisdoms_tagged.size == 0 %}
          <p class="empty-state">No wisdoms with this tag.</p>
        {% else %}
          <p class="bucket-count">{{ wisdoms_tagged.size }} wisdom{% if wisdoms_tagged.size != 1 %}s{% endif %} tagged <code>#{{ tag }}</code></p>
          <div class="wisdom-list">
            {% for w in wisdoms_tagged %}
              {% include wisdom-card.html wisdom=w %}
            {% endfor %}
          </div>
        {% endif %}
      LIQUID
    end
  end

  class TagPageGenerator < Generator
    safe true
    priority :low

    def generate(site)
      wisdoms = site.collections['wisdoms']&.docs || []
      tags = {}
      wisdoms.each do |w|
        (w.data['tags'] || []).each do |t|
          tags[t] ||= []
          tags[t] << w
        end
      end
      tags.each do |tag, list|
        slug = Jekyll::Utils.slugify(tag, mode: 'pretty')
        site.pages << TagPage.new(site, site.source, File.join('tags', slug), slug, list)
      end
    end
  end
end
