# frozen_string_literal: true

module JekyllFeed
  # Liquid tag that renders the <link> tag used for feed auto-discovery.
  #
  # Usage in a template: {% feed_meta %}
  class MetaTag < Liquid::Tag
    # Use Jekyll's native relative_url filter
    include Jekyll::Filters::URLFilters

    # Renders the <link rel="alternate" ...> tag pointing at the site's feed,
    # using `feed.path` (default "feed.xml") and `title`/`name` from the site config.
    def render(context)
      # Jekyll::Filters::URLFilters requires `@context` to be set in the environment.
      @context = context

      config = context.registers[:site].config
      path   = config.dig("feed", "path") || "feed.xml"
      title  = config["title"] || config["name"]

      attributes = {
        :type => "application/atom+xml",
        :rel  => "alternate",
        :href => absolute_url(path),
      }
      attributes[:title] = title if title

      attrs = attributes.map { |k, v| "#{k}=#{v.to_s.encode(:xml => :attr)}" }.join(" ")
      "<link #{attrs} />"
    end
  end
end
