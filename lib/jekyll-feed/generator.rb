# frozen_string_literal: true

require 'digest'

module JekyllFeed
  class Generator < Jekyll::Generator
    safe true
    priority :lowest

    # Main plugin action, called by Jekyll-core
    def generate(site)
      @site = site
      return if file_exists?(feed_path)

      # All feed documents use the same template, so just read it once.
      feed_source = File.read(feed_source_path).gsub(MINIFY_REGEX, "")

      # Any archive pages should link to the current feed, so set up that page
      # early so we can ask it for its URL later.
      current = PageWithoutAFile.new(@site, __dir__, "", feed_path)

      # Each feed needs to link to the archive feed before it, except for the
      # first archive feed.
      prev_archive = nil

      per_page = 10
      feed_posts = @site.posts.docs.reject {|d| d.draft?}

      # Never include the most recent post in an archive feed. We'll have some
      # overlap between the last archive feed and the current feed, but there's
      # no point duplicating _all_ the posts in both places.
      archive_page_count = (feed_posts.length - 1).div(per_page)

      dir = File.dirname(feed_path)
      base = File.basename(feed_path, '.*')
      ext = File.extname(feed_path)

      # Generate archive feeds first, starting from the oldest posts.
      1.upto(archive_page_count) do |pagenum|
        posts = feed_posts[(pagenum - 1) * per_page, per_page].reverse

        # If any of the posts in this page change, then we need to ensure that
        # RFC5005 consumers see the changes. Do this with the standard
        # cache-busting trick of including a hash of the important contents in
        # the filename. Also change this hash if the filename of the previous
        # page changed, because consumers will only work backward from the
        # newest page.
        digest = digest_posts(posts, prev_archive)
        page_path = File.join(dir, "#{base}-#{pagenum}-#{digest.hexdigest}#{ext}")

        page = PageWithoutAFile.new(@site, __dir__, "", page_path)
        prev_archive = content_for_file(page, feed_source, posts, prev_archive, current)
        @site.pages << prev_archive
      end

      # Finally, generate the current feed. We can't do this earlier because we
      # have to compute the filename of the last archive feed first.
      posts = feed_posts.reverse.take(per_page)
      @site.pages << content_for_file(current, feed_source, posts, prev_archive, nil)
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

    # Path to feed.xml template file
    def feed_source_path
      File.expand_path "feed.xml", __dir__
    end

    # Checks if a file already exists in the site source
    def file_exists?(file_path)
      if @site.respond_to?(:in_source_dir)
        File.exist? @site.in_source_dir(file_path)
      else
        File.exist? Jekyll.sanitized_path(@site.source, file_path)
      end
    end

    # Hash the important parts of an array of posts
    def digest_posts(posts, prev_archive)
      digest = Digest::MD5.new
      posts.each do |post|
        filtered = post.data.reject {|k, v| k == 'excerpt' || k == 'draft'}
        digest.file(post.path).update(filtered.to_s)
      end
      digest.update(prev_archive.url) unless prev_archive.nil?
      digest
    end

    # Generates contents for a file
    def content_for_file(file, file_source, posts, prev_archive, current)
      file.content = file_source
      file.data["layout"] = nil
      file.data["sitemap"] = false
      file.data["posts"] = posts
      file.data["prev_archive"] = prev_archive
      file.data["current"] = current
      file.data["xsl"] = file_exists?("feed.xslt.xml")
      file.output
      file
    end
  end
end
