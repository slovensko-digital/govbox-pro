module Common
  class BlankResultsComponent < ViewComponent::Base
    def initialize (reason = :not_found)
      @reason = reason
    end

    def before_render # rubocop:disable Metrics/MethodLength
      case @reason
      when :empty
        @text1 = t "blank_results.empty.text1"
        @text2 = t "blank_results.empty.text2"
        @icon = "magnifying-glass"
      when :not_found
        @text1 = t "blank_results.not_found.text1"
        @text2 = t "blank_results.not_found.text2"
        @icon = "magnifying-glass"
      when :all_done
        @text1 = t "blank_results.all_done.text1"
        @text2 = t "blank_results.all_done.text2"
        @icon = "hand-thumb-up"
      end
    end
  end
end
