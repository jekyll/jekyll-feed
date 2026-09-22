# frozen_string_literal: true

require "jekyll"
require "fileutils"
require "jekyll-feed/generator"

# Namespace for the jekyll-feed plugin: a Jekyll::Generator that builds Atom
# feed(s) for a site, plus the {% feed_meta %} Liquid tag used to advertise
# them in a page's <head>.
module JekyllFeed
  autoload :MetaTag,          "jekyll-feed/meta-tag"
  autoload :PageWithoutAFile, "jekyll-feed/page-without-a-file.rb"
end

Liquid::Template.register_tag "feed_meta", JekyllFeed::MetaTag
