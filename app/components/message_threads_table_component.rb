class MessageThreadsTableComponent < ViewComponent::Base
  renders_many :message_threads
  renders_one :next_page_area
  renders_one :blank_results_area

  def initialize(filter:, filter_subscription:, count_estimate: nil, query: nil, filter_subscriptions: nil)
    @filter = filter
    @filter_subscription = filter_subscription
    @count_estimate = count_estimate
    @query = query
    @filter_subscriptions = filter_subscriptions
  end
end
