class MessageThreadNote < ApplicationRecord
  belongs_to :message_thread

  after_create_commit ->(note) { EventBus.publish(:message_thread_note_created, note) }
  after_update_commit ->(note) { EventBus.publish(:message_thread_note_changed, note) }
end
