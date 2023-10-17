class MessageThreadsBulkActionsComponent < ViewComponent::Base
  def initialize(ids:)
    @ids = ids
  end
end
