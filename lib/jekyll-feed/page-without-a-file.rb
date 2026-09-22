# frozen_string_literal: true

module JekyllFeed
  # A Jekyll::Page whose content and data are set entirely in memory
  # (e.g., via `file.content = ...` and `file.data.merge!(...)`) rather
  # than read from a file on disk. Used to generate feed.xml without
  # requiring a corresponding template file in the site source.
  class PageWithoutAFile < Jekyll::Page
    # Overrides Jekyll::Page#read_yaml, which would otherwise try to read
    # and parse front matter from a file that doesn't exist.
    def read_yaml(*)
      @data ||= {}
    end
  end
end
