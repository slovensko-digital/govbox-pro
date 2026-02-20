class MessageThreadsBulkActionsComponent < ViewComponent::Base
  def initialize(ids:, signable:, filter: nil, filter_subscription: nil, count_estimate: nil)
    @ids = ids
    @signable = signable
    @filter = filter
    @filter_subscription = filter_subscription
    @count_estimate = count_estimate
  end
end
