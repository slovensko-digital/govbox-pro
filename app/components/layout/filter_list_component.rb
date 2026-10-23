class Layout::FilterListComponent < ViewComponent::Base
  def initialize(filters:, query: nil, show_heading: true)
    @filters = filters
    @query = query
    @show_heading = show_heading
  end
end
