class MessageThreadsTableComponent < ViewComponent::Base
  renders_many :message_threads
  renders_one :next_page_area
  renders_one :blank_results_area

  def initialize(filter:, filter_subscription:, count_estimate: nil)
    @filter = filter
    @filter_subscription = filter_subscription
    @count_estimate = count_estimate
  end
end
