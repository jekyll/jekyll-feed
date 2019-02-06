# frozen_string_literal: true

module JekyllFeed
  class MetaTag < Liquid::Tag
    # Use Jekyll's native relative_url filter
    include Jekyll::Filters::URLFilters

    def initialize(tag_name, args, tokens)
      super
      @args = args
    end

    def render(context)
      @context = context
      if @args.strip == "include: all"
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
      @generator ||= @context.registers[:site].generators.select { |it| it.is_a? JekyllFeed::Generator }.first # rubocop:disable Metrics/LineLength
    end

    def link(collection, category)
      attrs = attributes(collection, category).map { |k, v| %(#{k}="#{v}") }.join(" ")
      "<link #{attrs} />"
    end

    def attributes(collection, category)
      href = absolute_url(generator.feed_path(:collection => collection, :category => category))
      title = generator.feed_title(:collection => collection, :category => category)
      {
        :type  => "application/atom+xml",
        :rel   => "alternate",
        :href  => href,
        :title => title,
      }.delete_if { |_, v| v.strip.empty? }
    end

    def valid_collection
      return true if generator.collections.key? @collection

      invalidate_with_warning("collection")
    end

    def valid_category
      return true if @collection == "posts" || @category.nil?

      collection = generator.collections[@collection]
      return true if collection.key?("categories") && collection["categories"].include?(@category)

      invalidate_with_warning("category")
    end

    def invalidate_with_warning(type)
      Jekyll.logger.warn(
        "Jekyll Feed:",
        "Invalid #{type} name. Please review `{% feed_meta #{@args} %}`"
      )
      false
    end
  end
end
