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
  has_and_belongs_to_many :tags
  belongs_to :folder
  has_many :messages do
    def find_or_create_by_uuid!(uuid:) end
  end
  has_and_belongs_to_many :tags, through: :messages
  has_many :message_threads_tags

  after_create_commit ->(thread) { EventBus.publish(:message_thread_created, thread) }

  delegate :tenant, to: :folder

  def read?
    messages.all?(&:read)
  end

  def automation_rules_for_event(event)
    folder.tenant.automation_rules.where(trigger_event: event)
  end

  def visible_tags
    tags.where(visible: true)
  end
end
