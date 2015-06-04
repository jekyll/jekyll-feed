require 'spec_helper'

describe(Jekyll::JekyllFeed) do
  let(:overrides) do
    {
      "full_rebuild" => true,
      "source"      => source_dir,
      "destination" => dest_dir,
      "url"         => "http://example.org",
      "name"       => "My awesome site",
      "author"      => {
        "name"        => "Dr. Jekyll"
      },
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
    expect(Pathname.new(dest_dir("feed.xml"))).to exist
  end

  it "doesn't have multiple new lines or trailing whitespace" do
    expect(contents).to_not match /\s+\n/
    expect(contents).to_not match /\n{2,}/
  end

  it "puts all the posts in the feed.xml file" do
    expect(contents).to match /http:\/\/example\.org\/2014\/03\/04\/march-the-fourth\.html/
    expect(contents).to match /http:\/\/example\.org\/2014\/03\/02\/march-the-second\.html/
    expect(contents).to match /http:\/\/example\.org\/2013\/12\/12\/dec-the-second\.html/
  end

  it "does not include assets or any static files that aren't .html" do
    expect(contents).not_to match /http:\/\/example\.org\/images\/hubot\.png/
    expect(contents).not_to match /http:\/\/example\.org\/feeds\/atom\.xml/
  end

  it "preserves linebreaks in preformatted text in posts" do
    expect(contents).to match /Line 1\nLine 2\nLine 3/
  end

  it "supports post author name as an object" do
    expect(contents).to match /<author>\s*<name>Ben<\/name>\s*<email>ben@example.com<\/email>\s*<uri>http:\/\/ben.balter.com<\/uri>\s*<\/author>/
  end

  it "supports post author name as a string" do
    expect(contents).to match /<author>\s*<name>Pat<\/name>\s*<\/author>/
  end

  it "does not output author tag no author is provided" do
    expect(contents).not_to match /<author>\s*<name><\/name>\s*<\/author>/
  end

  it "converts markdown posts to HTML" do
    expect(contents).to match /&lt;p&gt;March the second!&lt;\/p&gt;/
  end

  it "converts uses last_modified_at where available" do
    expect(contents).to match /<updated>2015-05-12T13:27:59\+00:00<\/updated>/
  end

  context "parsing" do
    let(:feed) { RSS::Parser.parse(contents) }

    it "outputs an RSS feed" do
      expect(feed.feed_type).to eql("atom")
      expect(feed.feed_version).to eql("1.0")
      expect(feed.encoding).to eql("UTF-8")
    end

    it "outputs the link" do
      expect(feed.link.href).to eql("http://example.org/feed.xml")
    end

    it "outputs the generator" do
      expect(feed.generator.content).to eql("Jekyll")
      expect(feed.generator.version).to eql(Jekyll::VERSION)
    end

    it "includes the items" do
      expect(feed.items.count).to eql(7)
    end

    it "includes item contents" do
      post = feed.items.last
      expect(post.title.content).to eql("Dec The Second")
      expect(post.link.href).to eql("http://example.org/2013/12/12/dec-the-second.html")
      expect(post.published.content).to eql(Time.parse("2013-12-12"))
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
        # Quiet a warning that results from us passing the feed as a string
        next if warning.css("text").text =~ /Self reference doesn't match document location/
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
      expect(contents).to match /http:\/\/example\.org\/bass\/2014\/03\/04\/march-the-fourth\.html/
      expect(contents).to match /http:\/\/example\.org\/bass\/2014\/03\/02\/march-the-second\.html/
      expect(contents).to match /http:\/\/example\.org\/bass\/2013\/12\/12\/dec-the-second\.html/
    end
  end

  context "feed meta" do
    it "renders the feed meta" do
      index = File.read(dest_dir("index.html"))
      expected = '<link type="application/atom+xml" rel="alternate" href="http://example.org/feed.xml" title="My awesome site" />'
      expect(index).to include(expected)
    end
  end

  context "changing the feed path" do
    let(:config) do
      Jekyll.configuration(Jekyll::Utils.deep_merge_hashes(overrides, {"feed" => {"path" => "atom.xml"}}))
    end
    
    it "should write to atom.xml" do
      expect(Pathname.new(dest_dir("atom.xml"))).to exist
    end

    it "renders the feed meta with custom feed path" do
      index = File.read(dest_dir("index.html"))
      expected = '<link type="application/atom+xml" rel="alternate" href="http://example.org/atom.xml" title="My awesome site" />'
      expect(index).to include(expected)
    end
  end
end
