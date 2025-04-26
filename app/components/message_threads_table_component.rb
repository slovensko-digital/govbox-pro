class MessageThreadsTableComponent < ViewComponent::Base
  renders_many :message_threads
  renders_one :next_page_area
  renders_one :blank_results_area

  def initialize(filter:, filter_subscription:, failed_files: [])
    @filter = filter
    @filter_subscription = filter_subscription
    @failed_files = failed_files
  end
end
