class Layout::FilterListComponent < ViewComponent::Base
  def initialize(filters:, query: nil)
    @filters = filters
    @query = query
  end
end
