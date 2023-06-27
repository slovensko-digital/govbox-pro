class Layout::TagListComponent < ViewComponent::Base
    def initialize
        @tags = Current.tenant&.tags
    end
end
