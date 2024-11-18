class MessageThreadsBulkActionsComponent < ViewComponent::Base
  def initialize(ids: nil, signable:, filter: nil, query: nil, filter_subscription: nil)
    @ids = ids
    @signable = signable
    @filter = filter
    @query = query
    @filter_subscription = filter_subscription
  end

  def title
    return t(:selected_message, count: @ids.count) if @ids.present?
    return @filter.name if @filter.present? && @filter.is_a?(EverythingFilter)
    return "Správy z filtra '#{@filter.name}'" if @filter.present?
    return "Hľadaný výraz '#{@query}'" if @query.present?

    "Správy v schránke"
  end
end
