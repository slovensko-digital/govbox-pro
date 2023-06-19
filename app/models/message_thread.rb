# == Schema Information
#
# Table name: message_threads
#
#  id                                          :integer          not null, primary key
#  title                                       :string           not null
#  original_title                              :string           not null
#  merge_uuids                                 :uuid             not null
#  delivered_at                                :datetime         not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class MessageThread < ApplicationRecord
  belongs_to :folder
  has_many :messages do
    def find_or_create_by_uuid!(uuid:) end
  end
  has_and_belongs_to_many :tags, through: :messages

  after_create_commit ->(thread) { EventBus.publish(:message_thread_created, thread) }

  delegate :tenant, to: :folder
end
