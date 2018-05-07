# frozen_string_literal: true

DEFAULT_ENTRIES = [{ "feed_source_path" => "feed.xml", "feed_output_path" => "feed.xml" }]

module JekyllFeed
  class Generator < Jekyll::Generator
    safe true
    priority :lowest

    # Main plugin action, called by Jekyll-core
    def generate(site)
      @site = site
      entries.each do |e|
        @site.pages << content_for_file(e["feed_output_path"], feed_source_path(e["feed_source_path"]))
      end
    end

    private

    # Matches all whitespace that follows
    #   1. A '>', which closes an XML tag or
    #   2. A '}', which closes a Liquid tag
    # We will strip all of this whitespace to minify the template
    MINIFY_REGEX = %r!(?<=>|})\s+!

    # @return [Array<Object>] all of the template-to-output paths
    def entries
      return DEFAULT_ENTRIES unless @site.config["feed"] && (@site.config["feed"]["path"].is_a?(String) || @site.config["feed"]["paths"].is_a?(Array))

      if @site.config["feed"]["path"].nil?
        @site.config["feed"]["paths"]
      else
        [{ "feed_source_path" => "feed.xml", "feed_output_path" => @site.config["feed"]["path"] }]
      end
    end

    # @param [String] file path
    # @return [String] expanded file path
    def feed_source_path(file_path)
      if (file_path == "feed.xml")
        File.expand_path("feed.xml", __dir__)
      else
        File.expand_path(file_path, @site.source)
      end
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
    def content_for_file(file_path, file_source_path)
      file = PageWithoutAFile.new(@site, __dir__, "", file_path)
      file.content = File.read(file_source_path).gsub(MINIFY_REGEX, "")
      file.data["layout"] = nil
      file.data["sitemap"] = false
      file.data["xsl"] = file_exists?("feed.xslt.xml")
      file.output
      file
    end
  end
end
