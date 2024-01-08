class MessageThreadsBulkActionsComponent < ViewComponent::Base
  def initialize(ids:, filter: nil, filter_subscription: nil, user_is_signer: false)
    @ids = ids
    @filter = filter
    @filter_subscription = filter_subscription
    @user_is_signer = user_is_signer
  end
end
