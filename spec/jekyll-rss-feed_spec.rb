require 'spec_helper'

describe(Jekyll::JekyllRssFeed) do
  let(:overrides) do
    {
      "source"      => source_dir,
      "destination" => dest_dir,
      "url"         => "http://example.org",
      "collections" => {
        "my_collection" => { "output" => true },
        "other_things"  => { "output" => false }
      }
    }
  end
  let(:config) do
    Jekyll.configuration(overrides)
  end
  let(:site)     { Jekyll::Site.new(config) }
  let(:contents) { File.read(dest_dir("feed.xml")) }
  before(:each) do
    site.process
  end

  it "has no layout" do
    expect(contents).not_to match(/\ATHIS IS MY LAYOUT/)
  end

  it "creates a feed.xml file" do
    expect(File.exist?(dest_dir("feed.xml"))).to be_truthy
  end

  it "doesn't have multiple new lines or trailing whitespace" do
    expect(contents).to_not match /\s+\n/
    expect(contents).to_not match /\n{2,}/
  end

  it "puts all the posts in the feed.xml file" do
    expect(contents).to match /<link>http:\/\/example\.org\/2014\/03\/04\/march-the-fourth\.html<\/link>/
    expect(contents).to match /<link>http:\/\/example\.org\/2014\/03\/02\/march-the-second\.html<\/link>/
    expect(contents).to match /<link>http:\/\/example\.org\/2013\/12\/12\/dec-the-second\.html<\/link>/
  end

  it "does not include assets or any static files that aren't .html" do
    expect(contents).not_to match /<link>http:\/\/example\.org\/images\/hubot\.png<\/link>/
    expect(contents).not_to match /<link>http:\/\/example\.org\/feeds\/atom\.xml<\/link>/
  end

  it "preserves linebreaks in preformatted text in posts" do
    expect(contents).to match /Line 1\nLine 2\nLine 3/
  end

  context "parsing" do
    let(:feed) { RSS::Parser.parse(contents) }

    it "outputs an RSS feed" do
      expect(feed.feed_type).to eql("rss")
      expect(feed.feed_version).to eql("2.0")
      expect(feed.encoding).to eql("UTF-8")
    end

    it "outputs the link" do
      expect(feed.channel.link).to eql("http://example.org")
    end

    it "outputs the generator" do
      expect(feed.channel.generator).to match(/Jekyll v\d+\.\d+\.\d+/)
    end

    it "includes the items" do
      expect(feed.items.count).to eql(6)
    end

    it "includes item contents" do
      post = feed.items.last
      expect(post.title).to eql("Dec The Second")
      expect(post.link).to eql("http://example.org/2013/12/12/dec-the-second.html")
      expect(post.pubDate).to eql(Time.parse("2013-12-12"))
    end
  end

  context "validation" do
    it "validates" do
      # See https://validator.w3.org/docs/api.html
      url = "https://validator.w3.org/feed/check.cgi?output=soap12"
      response = Typhoeus.post(url, body: { rawdata: contents }, accept_encoding: "gzip")
      pending "Something went wrong with the W3 validator" unless response.success?
      result  = Nokogiri::XML(response.body)
      result.remove_namespaces!

      result.css("warning").each do |warning|
        warn "Validation warning: #{warning.css("text").text} on line #{warning.css("line").text} column #{warning.css("column").text}"
      end

      errors = result.css("error").map do |error|
        "Validation error: #{error.css("text").text} on line #{error.css("line").text} column #{error.css("column").text}"
      end

      expect(result.css("validity").text).to eql("true"), errors.join("\n")
    end
  end

  context "with a baseurl" do
    let(:config) do
      Jekyll.configuration(Jekyll::Utils.deep_merge_hashes(overrides, {"baseurl" => "/bass"}))
    end

    it "correctly adds the baseurl to the posts" do
      expect(contents).to match /<link>http:\/\/example\.org\/bass\/2014\/03\/04\/march-the-fourth\.html<\/link>/
      expect(contents).to match /<link>http:\/\/example\.org\/bass\/2014\/03\/02\/march-the-second\.html<\/link>/
      expect(contents).to match /<link>http:\/\/example\.org\/bass\/2013\/12\/12\/dec-the-second\.html<\/link>/
    end
  end

  context "feed meta" do
    it "renders the feed meta" do
      index = File.read(dest_dir("index.html"))
      expected = '<link type="application/atom+xml" rel="alternate" href="http://example.org/feed.xml" />'
      expect(index).to include(expected)
    end
  end
end
