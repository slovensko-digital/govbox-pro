class Layout::SystemFilterListComponent < ViewComponent::Base
  def initialize(tags:, filters: [], query: nil)
    @tags = tags
    @filters = filters
    @query = query
  end

  def visible_tags
    pinned_queries = @filters.map(&:query).to_set
    @tags.reject { |tag| pinned_queries.include?("label:(#{tag.name})") }
  end
end
