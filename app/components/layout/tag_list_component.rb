class Layout::TagListComponent < ViewComponent::Base
    def initialize
        @tags = Current.tenant&.tags.where(visible: true)
    end
end
