# == Schema Information
#
# Table name: message_threads_tags
#
#  id                                          :integer          not null, primary key
#  message_thread_id                           :integer          not null
#  tag_id                                      :integer          not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class MessageThreadsTag < ApplicationRecord
  belongs_to :message_thread
  belongs_to :tag

  # used for joins only
  has_many :tag_groups, primary_key: :tag_id, foreign_key: :tag_id

  validates :tag_id, :message_thread_id, presence: true
  validates_uniqueness_of :tag_id, scope: :message_thread_id
  validate :thread_and_tag_tenants_matches

  after_commit ->(message_threads_tag) { EventBus.publish(:message_thread_tag_changed, message_threads_tag) }

  def thread_and_tag_tenants_matches
    unless message_thread.folder.box.tenant == tag.tenant && tag.tenant
      errors.add :name, 'Unpermitted combination of tag and message thread'
    end
  end

  def self.process_changes_for_message_thread(message_thread:, tags_to_add: [], tags_to_remove: [])
    create_attributes = tags_to_add.map { |tag| { message_thread: message_thread, tag: tag } }

    MessageThreadsTag.transaction do
      MessageThreadsTag.create(create_attributes)
      MessageThreadsTag.where(message_thread: message_thread, tag: tags_to_remove).destroy_all
    end
  end
end
