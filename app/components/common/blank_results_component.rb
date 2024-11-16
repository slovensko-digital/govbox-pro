module Common
  class BlankResultsComponent < ViewComponent::Base
    def initialize (reason = :not_found)
      @reason = reason
    end

    def before_render # rubocop:disable Metrics/MethodLength
      case @reason
      when :filters
        @text1 = t "blank_results.filters.text1"
        @text2 = t "blank_results.filters.text2"
        @icon = "bookmark-slash"
      when :rules
        @text1 = t "blank_results.rules.text1"
        @text2 = t "blank_results.rules.text2"
        @icon = "funnel-slash"
      when :tags
        @text1 = t "blank_results.tags.text1"
        @text2 = t "blank_results.tags.text2"
        @icon = "tag-slash"
      when :not_found
        @text1 = t "blank_results.not_found.text1"
        @text2 = t "blank_results.not_found.text2"
        @icon = "magnifying-glass"
      end
    end
  end
end
