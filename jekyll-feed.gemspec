# frozen_string_literal: true

require_relative "lib/jekyll-feed/version"

Gem::Specification.new do |spec|
  spec.name             = "jekyll-feed"
  spec.version          = Jekyll::Feed::VERSION
  spec.authors          = ["Ben Balter"]
  spec.email            = ["ben.balter@github.com"]
  spec.summary          = "A Jekyll plugin to generate an Atom feed of your Jekyll posts"
  spec.homepage         = "https://github.com/jekyll/jekyll-feed"
  spec.license          = "MIT"

  spec.files            = Dir["lib/**/*"]
  spec.extra_rdoc_files = Dir["README.md", "History.markdown", "LICENSE.txt"]
  spec.test_files       = spec.files.grep(%r!^spec/!)
  spec.require_paths    = ["lib"]

  spec.required_ruby_version = ">= 2.5.0"

  spec.add_dependency "jekyll", ">= 3.7", "< 5.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "nokogiri", "~> 1.6"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop-jekyll", "~> 0.12.0"
  spec.add_development_dependency "typhoeus", ">= 0.7", "< 2.0"
end
