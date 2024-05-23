class MessageThreadsTableComponent < ViewComponent::Base
  renders_many :message_threads
  renders_one :next_page_area

  attr_reader :filter, :query, :filter_subscription

  def initialize(filter: nil, query: nil, filter_subscription:)
    @filter = filter
    @query = query
    @filter_subscription = filter_subscription
  end
end
