module JekyllFeed
  class Generator < Jekyll::Generator
    safe true
    priority :lowest

    # Main plugin action, called by Jekyll-core
    def generate(site)
      @site = site
      
      return if file_exists?(feed_path) and file_exists?(json_feed_path)
      @site.pages << xml_content_for_file(feed_path, feed_source_path)
      @site.pages << json_content_for_file(json_feed_path, feed_json_source_path)
    end

    private

    # Matches all whitespace that follows
    #   1. A '>', which closes an XML tag or
    #   2. A '}', which closes a Liquid tag
    # We will strip all of this whitespace to minify the template
    MINIFY_REGEX = %r!(?<=>|})\s+!

    # Path to feed from config, or feed.xml for default
    def feed_path
      if @site.config["feed"] && @site.config["feed"]["path"]
        @site.config["feed"]["path"]
      else
        "feed.xml"
      end
    end

    # Path to JSON feed from config, or feed.json for default
    def json_feed_path
      if @site.config["feed"] && @site.config["feed"]["path"]
        @site.config["feed"]["path"]
      else
        "feed.json"
      end
    end

    # Path to feed.xml template file
    def feed_source_path
      File.expand_path "./feed.xml", File.dirname(__FILE__)
    end

    # Path to feed.json template file
    def feed_json_source_path
      File.expand_path "./feed.json", File.dirname(__FILE__)
    end

    # Checks if a file already exists in the site source
    def file_exists?(file_path)
      if @site.respond_to?(:in_source_dir)
        File.exist? @site.in_source_dir(file_path)
      else
        File.exist? Jekyll.sanitized_path(@site.source, file_path)
      end
    end

    # Generates contents for a file
    def content_for_file(file_path, file_source_path, regex)
      file = PageWithoutAFile.new(@site, File.dirname(__FILE__), "", file_path)
      content = File.read(file_source_path)

      if regex
        content = content.gsub(regex, "")
      end

      file.content = content
      file.data["layout"] = nil
      file.data["sitemap"] = false
      file
    end

    def xml_content_for_file(file_path, file_source_path)
      file = content_for_file(file_path, file_source_path, MINIFY_REGEX)
      file.data["xsl"] = file_exists?("feed.xslt.xml")
      file.output
      file
    end

    def json_content_for_file(file_path, file_source_path)
      file = content_for_file(file_path, file_source_path, nil)
      file.output
      file
    end
  end
end
