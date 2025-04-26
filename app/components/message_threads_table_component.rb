class MessageThreadsTableComponent < ViewComponent::Base
  renders_many :message_threads
  renders_one :next_page_area
  renders_one :blank_results_area

  def initialize(filter:, filter_subscription:, sticky_note_type: nil, sticky_note_data: nil)
    @filter = filter
    @filter_subscription = filter_subscription
    @sticky_note_type = sticky_note_type
    @sticky_note_data = sticky_note_data
  end
end
