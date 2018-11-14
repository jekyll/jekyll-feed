# frozen_string_literal: true

module JekyllFeed
  class MetaTag < Liquid::Tag
    # Use Jekyll's native relative_url filter
    include Jekyll::Filters::URLFilters

    def render(context)
      @context = context
      @generator = generator
      links = []
      generator.collections.each do |collection, meta|
        (meta["categories"] + [nil]).each do |category|
          attrs = attributes(collection, category).map { |k, v| %(#{k}="#{v}") }.join(" ")
          links << "<link #{attrs} />"
        end
      end
      links.reverse.join "\n"
    end

    private

    def config
      @config ||= @context.registers[:site].config
    end

    def generator
      @generator ||= @context.registers[:site].generators.select { |it| it.is_a? JekyllFeed::Generator }.first # rubocop:disable Metrics/LineLength
    end

    def attributes(collection, category)
      href = absolute_url(generator.feed_path(:collection => collection, :category => category))
      {
        :type  => "application/atom+xml",
        :rel   => "alternate",
        :href  => href,
        :title => title,
      }.keep_if { |_, v| v }
    end

    def title
      config["title"] || config["name"]
    end
  end
end
