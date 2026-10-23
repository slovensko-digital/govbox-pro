class MessageThreadsBulkActionsComponent < ViewComponent::Base
  def initialize(ids:, signable:, filter: nil, filter_subscription: nil, count_estimate: nil, query: nil, filter_subscriptions: nil)
    @ids = ids
    @signable = signable
    @filter = filter
    @filter_subscription = filter_subscription
    @count_estimate = count_estimate
    @query = query
    @filter_subscriptions = filter_subscriptions || Array(filter_subscription)
  end

  def title
    return @filter.name if @filter
    return "Hľadaný výraz '#{@query}'" if @query.present?

    "Správy v schránke"
  end
end
