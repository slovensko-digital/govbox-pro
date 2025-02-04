class AddInboxTagToThreadsJob < ApplicationJob
  def perform
    MessageThread.find_each { |message_thread| AddInboxTagToThreadJob.perform_later(message_thread) }
  end
end
