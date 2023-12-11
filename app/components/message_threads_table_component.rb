class MessageThreadsTableComponent < ViewComponent::Base
  renders_many :message_threads
  renders_one :next_page_area

  attr_reader :filter, :query

  def initialize(filter: nil, query: nil)
    @filter = filter
    @query = query
  end
end
