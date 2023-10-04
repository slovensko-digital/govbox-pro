class Layout::FilterListComponent < ViewComponent::Base
  def initialize(filters:)
    @filters = filters
  end
end
