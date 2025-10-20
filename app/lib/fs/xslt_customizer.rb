module Fs
  module XsltCustomizer
    def self.apply_customizations(xslt)
      if html_template?(xslt)
        customize_html_template(xslt)
      else
        customize_text_template(xslt)
      end
    end

    def self.customize_html_template(xslt)
      result = xslt.dup

      result = add_bold_to_content_vis_css(result)

      wrap_values_in_strong_skip_named_templates(result)
    end

    def self.customize_text_template(xslt)
      result = xslt.dup

      result = change_output_method_to_html(result)

      wrap_values_in_strong_skip_named_templates(result)
    end

    def self.html_template?(xslt)
      xslt.include?('method="html"')
    end

    def self.add_bold_to_content_vis_css(xslt)
      xslt.gsub(/\.contentVis\s*\{([^}]*)\}/m) do |match|
        css_content = ::Regexp.last_match(1)

        next match if css_content.include?('font-weight')

        ".contentVis {#{css_content}\n font-weight: bold;\n  }"
      end
    end

    def self.change_output_method_to_html(xslt)
      xslt.gsub('method="text"', 'method="html"')
    end

    def self.wrap_values_in_strong_skip_named_templates(xslt)
      result = xslt.dup
      offset = 0

      xslt.scan(%r{<xsl:value-of[^>]*/>}).each do |value_of_match|
        match_index = xslt.index(value_of_match, offset)
        next unless match_index

        context_before = xslt[0...match_index]

        if inside_named_template?(context_before)
          offset = match_index + value_of_match.length
          next
        end

        result_index = result.index(value_of_match, offset)
        next unless result_index

        result[result_index...result_index + value_of_match.length] = "<strong>#{value_of_match}</strong>"

        offset = match_index + value_of_match.length
      end

      result
    end

    def self.inside_named_template?(context_before)
      open_named_templates = context_before.scan(/<xsl:template\s+name=/).length
      close_templates = context_before.scan("</xsl:template>").length

      open_named_templates > close_templates
    end
  end
end
