module Jekyll
  class FeedMetaTag < Liquid::Tag
    def render(context)
      @context = context
      attrs    = attributes.map { |k, v| %(#{k}="#{v}") }.join(" ")
      "<link #{attrs} />"
    end

    private

    def config
      @context.registers[:site].config
    end

    def attributes
      {
        :type  => "application/atom+xml",
        :rel   => "alternate",
        :href  => "#{url}/#{path}",
        :title => title
      }.keep_if { |_, v| v }
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
        begin
          URI.join(config["url"], config["baseurl"])
        rescue
          raise Jekyll::Errors::JekyllFeed::InvalidURLConfigurationError, url_error
        end
      elsif config["github"] && config["github"]["url"]
        config["github"]["url"]
      end
    end

    def url_error
      <<-EOS
One or both of `url` and `baseurl` are invalid in your configuration file. We were unable to create a valid URL with them:

    url = #{config["url"].inspect}
    baseurl = #{config["baseurl"].inspect}

Please correct them, or remove them from your configuration.
      EOS
    end

    def title
      config["title"] || config["name"]
    end
  end
end

Liquid::Template.register_tag("feed_meta", Jekyll::FeedMetaTag)
