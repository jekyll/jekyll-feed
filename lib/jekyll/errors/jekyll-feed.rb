module Jekyll
  module Errors
    module JekyllFeed
      InvalidURLConfigurationError = Class.new(Jekyll::Errors::FatalException)
    end
  end
end
