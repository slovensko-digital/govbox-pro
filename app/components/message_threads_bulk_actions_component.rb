class MessageThreadsBulkActionsComponent < ViewComponent::Base
  def initialize(ids:, filter: nil, filter_subscription: nil)
    @ids = ids
    @filter = filter
    @filter_subscription = filter_subscription
  end
end
