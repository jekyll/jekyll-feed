require "fileutils"

module Jekyll
  class JekyllFeed < Jekyll::Generator
    safe true
    priority :lowest

    # Main plugin action, called by Jekyll-core
    def generate(site)
      @site = site
      @site.config["time"] = Time.new
      unless feed_exists?
        @site.pages << feed_content
      end
    end

    private

    # Path to feed from config, or feed.xml for default
    def path
      if @site.config["feed"] && @site.config["feed"]["path"]
        @site.config["feed"]["path"]
      else
        "feed.xml"
      end
    end

    # Path to feed.xml template file
    def source_path
      File.expand_path "../feed.xml", File.dirname(__FILE__)
    end

    def feed_content
      feed = PageWithoutAFile.new(@site, File.dirname(__FILE__), "", path)
      feed.content = File.read(source_path).gsub(/(?<!\")\s+([<{])/, '\1')
      feed.data["layout"] = nil
      feed.data["sitemap"] = false
      feed.output
      feed
    end

    # Checks if a feed already exists in the site source
    def feed_exists?
      if @site.respond_to?(:in_source_dir)
        File.exist? @site.in_source_dir(path)
      else
        File.exist? Jekyll.sanitized_path(@site.source, path)
      end
    end
  end
end
