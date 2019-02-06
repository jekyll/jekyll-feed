# frozen_string_literal: true

module JekyllFeed
  class MetaTag < Liquid::Tag
    # Use Jekyll's native relative_url filter
    include Jekyll::Filters::URLFilters

    def initialize(tag_name, args, tokens)
      super
      @args = args.strip
    end

    def render(context)
      @context = context
      @collection = nil
      @category   = nil

      if @args == "include: all"
        links = []
        generator.collections.each do |collection, meta|
          (meta["categories"] + [nil]).each do |category|
            links << link(collection, category)
          end
        end
        links.reverse.join "\n"
      else
        @collection, @category = @args.split(" ")
        @collection ||= "posts"
        link(@collection, @category) if valid_collection && valid_category
      end
    end

    private

    def config
      @config ||= @context.registers[:site].config
    end

    def generator
      @generator ||= @context.registers[:site].generators.find do |generator|
        generator.is_a? JekyllFeed::Generator
      end
    end

    def link(collection, category)
      attrs = attributes(collection, category).map { |k, v| %(#{k}="#{v}") }.join(" ")
      "<link #{attrs} />"
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

    def valid_collection
      return true if generator.collections.key? @collection

      Jekyll.logger.warn(
        "Jekyll Feed:",
        "Invalid collection name. Please review `{% feed_meta #{@args} %}`"
      )
      false
    end

    def valid_category
      return true if @collection == "posts" || @category.nil?

      collection = generator.collections[@collection]
      return true if collection.key?("categories") && collection["categories"].include?(@category)

      Jekyll.logger.warn(
        "Jekyll Feed:",
        "Invalid category name. Please review `{% feed_meta #{@args} %}`"
      )
      false
    end
  end
end
