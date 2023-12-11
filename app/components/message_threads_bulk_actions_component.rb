class MessageThreadsBulkActionsComponent < ViewComponent::Base
  def initialize(ids: nil, filter: nil, query: nil)
    @ids = ids
    @filter = filter
    @query = query
  end

  def title
    return t(:selected_message, count: @ids.count) if @ids.present?
    return "Správy z filtra '#{@filter.name}'" if @filter.present?
    return "Správy vyhovujúce hľadanému výrazu '#{@query}'" if @query.present?

    "Správy v schránke"
  end
end
