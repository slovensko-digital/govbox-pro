class MessageThreadsBulkActionsComponent < ViewComponent::Base
  def initialize(ids: nil, filter: nil, query: nil, filter_subscription: nil)
    @ids = ids
    @filter = filter
    @query = query
    @filter_subscription = filter_subscription
  end

  def title
    return t(:selected_message, count: @ids.count) if @ids.present?
    return "Správy z filtra '#{@filter.name}'" if @filter.present?
    return "Hľadaný výraz '#{@query}'" if @query.present?

    "Správy v schránke"
  end
end
