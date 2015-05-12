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
end
