# frozen_string_literal: true

require "jekyll"
require "typhoeus" unless Gem.win_platform?
require "nokogiri"
require "rss"
require File.expand_path("../lib/jekyll-feed", __dir__)

Jekyll.logger.log_level = :error

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = "random"

  SOURCE_DIR = File.expand_path("../fixtures", __FILE__)
  SOURCE_DIR2 = File.expand_path("../fixtures2", __FILE__)
  DEST_DIR   = File.expand_path("../dest",     __FILE__)

  def source_dir(*files)
    File.join(SOURCE_DIR, *files)
  end

  def source_dir2(*files)
    File.join(SOURCE_DIR2, *files)
  end

  def dest_dir(*files)
    File.join(DEST_DIR, *files)
  end

  def make_context(registers = {})
    Liquid::Context.new({}, {}, { :site => site }.merge(registers))
  end
end
