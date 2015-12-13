require 'fileutils'

module Jekyll
  class PageWithoutAFile < Page
    def read_yaml(*)
      @data ||= {}
    end
  end

  module StripWhitespace
    def strip(input)
      input.to_s.strip
    end
  end

  class FeedMetaTag < Liquid::Tag
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
        config["url"]
      elsif config["github"] && config["github"]["url"]
        config["github"]["url"]
      end
    end

    def render(context)
      @context = context
      "<link type=\"application/atom+xml\" rel=\"alternate\" href=\"#{url}/#{path}\" title=\"#{config["name"]}\" />"
    end
  end

  class JekyllFeed < Jekyll::Generator
    safe true
    priority :lowest

    # Path to feed from config, or feed.xml for default
    def path
      if @site.config["feed"] && @site.config["feed"]["path"]
        @site.config["feed"]["path"]
      else
        "feed.xml"
      end
    end

    # Main plugin action, called by Jekyll-core
    def generate(site)
      @site = site
      @site.config["time"] = Time.new
      unless feed_exists?
        @site.pages << feed_content
      end
    end

    # Path to feed.xml template file
    def source_path
      File.expand_path "feed.xml", File.dirname(__FILE__)
    end

    def feed_content
      feed = PageWithoutAFile.new(@site, File.dirname(__FILE__), "", path)
      feed.content = File.read(source_path).gsub(/\s*\n\s*/, "\n").gsub(/\s+{%/, "{%").gsub(/\s+</,"<")
      feed.data["layout"] = nil
      feed.data['sitemap'] = false
      feed.output
      feed
    end

    # Checks if a feed already exists in the site source
    def feed_exists?
      if @site.respond_to?(:in_source_dir)
        File.exists? @site.in_source_dir(path)
      else
        File.exists? Jekyll.sanitized_path(@site.source, path)
      end
    end
  end
end

unless defined? Liquid::StandardFilters.strip
    Liquid::Template.register_filter(Jekyll::StripWhitespace)
end

Liquid::Template.register_tag('feed_meta', Jekyll::FeedMetaTag)
