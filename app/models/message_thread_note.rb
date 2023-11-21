# == Schema Information
#
# Table name: message_thread_notes
#
#  id                :bigint           not null, primary key
#  note              :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  message_thread_id :bigint           not null
#
class MessageThreadNote < ApplicationRecord
  belongs_to :message_thread

  after_create_commit ->(note) { EventBus.publish(:message_thread_note_created, note) }
  after_update_commit ->(note) { EventBus.publish(:message_thread_note_changed, note) }
end
