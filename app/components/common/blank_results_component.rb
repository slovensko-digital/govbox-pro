module Common
  class BlankResultsComponent < ViewComponent::Base
    def initialize(reason = :not_found)
      @reason = reason
    end

    def before_render
      icon_mappings = {
        filters: "bookmark-slash",
        rules: "funnel-slash",
        tags: "tag-slash",
        not_found: "magnifying-glass",
        boxes: "inbox-stack",
        notifications: "bell-slash"
      }

      @header = t "blank_results.#{@reason}.header"
      @description = t "blank_results.#{@reason}.description"
      @icon = icon_mappings[@reason]
    end
  end
end
