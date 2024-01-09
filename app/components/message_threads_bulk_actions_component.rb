class MessageThreadsBulkActionsComponent < ViewComponent::Base
  def initialize(ids:, signable:, filter: nil, filter_subscription: nil)
    @ids = ids
    @signable = signable
    @filter = filter
    @filter_subscription = filter_subscription
  end
end
