class MessageThread < ApplicationRecord
  belongs_to :folder
  has_many :messages do
    def find_or_create_by_uuid!(uuid:) end
  end

  after_create_commit ->(thread) { EventBus.publish(:message_thread_created, thread) }

  delegate :tenant, to: :folder
end
