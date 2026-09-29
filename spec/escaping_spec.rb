# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

describe "JekyllFeed output escaping" do
  let(:tmp_dir) { Dir.mktmpdir("jekyll-feed") }
  let(:tmp_source) { File.join(tmp_dir, "source") }
  let(:tmp_dest) { File.join(tmp_dir, "dest") }
  let(:overrides) { {} }
  let(:posts) { {} }
  let(:site) do
    Jekyll::Site.new(Jekyll.configuration({
      "source"      => tmp_source,
      "destination" => tmp_dest,
      "url"         => "http://example.org",
      "plugins"     => ["jekyll-feed"],
    }.merge(overrides)))
  end
  let(:contents) { File.read(File.join(tmp_dest, "feed.xml")) }
  let(:feed) do
    Nokogiri::XML(contents, &:strict).tap(&:remove_namespaces!)
  end
  let(:entries) { feed.xpath("/feed/entry") }

  before(:each) do
    FileUtils.mkdir_p(File.join(tmp_source, "_posts"))
    posts.each do |name, (front_matter, body)|
      File.write(
        File.join(tmp_source, "_posts", name),
        "#{front_matter.merge("title" => "Post").to_yaml}---\n#{body}\n"
      )
    end
    site.process
  end

  after(:each) do
    FileUtils.rm_rf(tmp_dir)
  end

  context "with a post.lang containing markup" do
    let(:lang) { 'en" xml:base="https://evil.example/" xmlns:x="urn:x" x:injected="1' }
    let(:posts) { { "2026-01-01-lang.md" => [{ "lang" => lang }, "Hello"] } }

    it "escapes the language attribute" do
      expect(contents).to include(
        '<entry xml:lang="en&quot; xml:base=&quot;https://evil.example/&quot; ' \
        'xmlns:x=&quot;urn:x&quot; x:injected=&quot;1">'
      )
    end

    it "does not inject additional attributes" do
      entry = entries.first
      expect(entry.attributes.keys).to eql(["lang"])
      expect(entry["lang"]).to eql(lang)
    end
  end

  context "with a post.lang that closes the element" do
    let(:posts) do
      { "2026-01-01-lang.md" => [{ "lang" => 'en"><title>Forged</title><x a="' }, "Hello"] }
    end

    it "produces a well-formed feed with no injected elements" do
      expect(entries.length).to eql(1)
      expect(entries.first.xpath("title").map(&:text)).to eql(["Post"])
    end
  end

  context "with a site.lang containing markup" do
    let(:lang) { 'en" x="1' }
    let(:overrides) { { "lang" => lang } }
    let(:posts) { { "2026-01-01-post.md" => [{}, "Hello"] } }

    it "escapes the feed language attributes" do
      expect(contents).to include('<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="en&quot; x=&quot;1">')
      expect(contents).to include('hreflang="en&quot; x=&quot;1"')
      expect(feed.root["lang"]).to eql(lang)
      expect(feed.at_xpath("/feed/link[@rel='alternate']")["hreflang"]).to eql(lang)
    end
  end

  context "with post content containing a CDATA end token" do
    let(:body) do
      "<p>hi</p>]]></content></entry><entry><title>Forged entry</title>" \
        "<id>urn:forged</id><content type=\"html\"><![CDATA[x"
    end
    let(:posts) { { "2026-01-01-raw.html" => [{}, body] } }

    it "produces a well-formed feed with no injected entries" do
      expect(entries.length).to eql(1)
      expect(feed.xpath("//id").map(&:text)).to_not include("urn:forged")
    end

    it "preserves the content" do
      expect(entries.first.at_xpath("content").text).to eql(body)
    end
  end

  context "with a post description containing a CDATA end token" do
    let(:description) { "Summary ]]> with an end token" }
    let(:posts) { { "2026-01-01-summary.md" => [{ "description" => description }, "Hello"] } }

    it "produces a well-formed feed that preserves the summary" do
      expect(entries.length).to eql(1)
      expect(entries.first.at_xpath("summary").text).to eql(description)
    end
  end
end
