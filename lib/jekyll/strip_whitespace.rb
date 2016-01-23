module Jekyll
  module StripWhitespace
    def strip(input)
      input.to_s.strip
    end
  end
end

unless Liquid::StandardFilters.method_defined?(:strip)
  Liquid::Template.register_filter(Jekyll::StripWhitespace)
end
