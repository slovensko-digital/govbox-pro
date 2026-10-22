class Searchable::ReindexMessageThreadJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_concurrency_rule(
    label: -> { "Searchable::ReindexMessageThreadJob-#{arguments.first}" },
    apply_label: true,
    total_limit: 2,
    perform_limit: 1
  )

  def perform(message_thread_id)
    message_thread = ::MessageThread.find_by_id(message_thread_id)

    return if message_thread.nil?

    ::Searchable::Indexer.index_message_thread(message_thread)
  end

  def adjust_priority?
    true
  end
end
