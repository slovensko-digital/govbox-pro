# == Schema Information
#
# Table name: message_threads
#
#  id                                          :integer          not null, primary key
#  title                                       :string           not null
#  original_title                              :string           not null
#  merge_uuids                                 :uuid             not null
#  delivered_at                                :datetime         not null
#  last_message_delivered_at                   :datetime         not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class MessageThread < ApplicationRecord
  has_and_belongs_to_many :tags
  belongs_to :folder
  has_many :messages do
    def find_or_create_by_uuid!(uuid:)
    end
  end
  has_and_belongs_to_many :tags, through: :messages
  has_many :message_threads_tags
  has_many :tag_users, through: :message_threads_tags
  has_many :merge_identifiers, class_name: 'MessageThreadMergeIdentifier', dependent: :destroy

  after_create_commit ->(thread) { EventBus.publish(:message_thread_created, thread) }

  delegate :tenant, to: :folder

  def read?
    messages.all?(&:read)
  end

  def automation_rules_for_event(event)
    folder.tenant.automation_rules.where(trigger_event: event)
  end

  def self.merge_threads
    transaction do
      target_thread = self.first
      self.all.each do |thread|
        if thread != target_thread
          thread.merge_identifiers.update_all(message_thread_id: target_thread.id)
          target_thread.last_message_delivered_at = max(target_thread.last_message_delivered_at, thread.last_message_delivered_at)
          thread.messages.each do |message|
            message.thread = target_thread
            message.save!
          end
          thread.tags.each do |tag|
            target_thread.tags.push(tag) unless target_thread.tags.include?(tag)
          end
          thread.destroy!
        end
      end
    end
  end
end
