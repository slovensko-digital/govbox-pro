class MessageThreadNote < ApplicationRecord
  belongs_to :message_thread

  after_commit ->(note) { EventBus.publish(:message_thread_note_committed, note) }
end
