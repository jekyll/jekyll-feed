module Jekyll
  class FeedMetaTag < Liquid::Tag

    def render(context)
      @context = context
      "<link type=\"application/atom+xml\" rel=\"alternate\" href=\"#{url}/#{path}\" title=\"#{config["name"]}\" />"
    end

    private

    def config
      @context.registers[:site].config
    end

    def path
      if config["feed"] && config["feed"]["path"]
        config["feed"]["path"]
      else
        "feed.xml"
      end
    end

    def url
      if config["url"]
        URI.join(config["url"], config["baseurl"])
      elsif config["github"] && config["github"]["url"]
        config["github"]["url"]
      end
    end
  end
end

Liquid::Template.register_tag("feed_meta", Jekyll::FeedMetaTag)
