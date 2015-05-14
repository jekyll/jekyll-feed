# Jekyll RSS feed plugin

A Jekyll plugin to generate an RSS feed for your Jekyll posts

[![Build Status](https://travis-ci.org/jekyll/jekyll-rss-feed.svg)](https://travis-ci.org/jekyll/jekyll-rss-feed) [![Gem Version](https://badge.fury.io/rb/jekyll-rss-feed.svg)](http://badge.fury.io/rb/jekyll-rss-feed)

## Installation

Add this line to your site's Gemfile:

```ruby
gem 'jekyll-rss-feed'
```

And then add this line to your site's `_config.yml`:

```yml
gems:
  - jekyll-rss-feed
```

## Usage

The plugin will automatically generate an RSS feed at `/feed.xml`.

Optional configuration options:

* `rss_limit`: number of posts to be included in the feed; default `nil`

### Meta tags

The plugin exposes a helper tag to expose the appropriate meta tags to support automated discovery of your feed. Simply place `{% feed_meta %}` someplace in your template's `<head>` section, to output the necessary metadata.

## Contributing

1. Fork it (https://github.com/jekyll/jekyll-rss-feed/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
