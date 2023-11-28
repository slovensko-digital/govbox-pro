# == Schema Information
#
# Table name: message_threads
#
#  id                        :bigint           not null, primary key
#  delivered_at              :datetime         not null
#  last_message_delivered_at :datetime         not null
#  original_title            :string           not null
#  title                     :string           not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  box_id                    :bigint           not null
#  folder_id                 :bigint
#
class MessageThread < ApplicationRecord
  belongs_to :folder, optional: true # do not use, will be removed
  belongs_to :box
  has_one :message_thread_note, dependent: :destroy
  has_many :messages, dependent: :destroy, inverse_of: :thread do
    def find_or_create_by_uuid!(uuid:)
    end
  end
  has_many :message_drafts
  has_many :message_threads_tags, dependent: :destroy
  has_many :tags, through: :message_threads_tags
  has_many :tag_users, through: :message_threads_tags
  has_many :merge_identifiers, class_name: 'MessageThreadMergeIdentifier', dependent: :destroy

  validates :title, presence: true

  attr_accessor :search_highlight

  after_create_commit ->(thread) { EventBus.publish(:message_thread_created, thread) }
  after_update_commit ->(thread) { EventBus.publish(:message_thread_changed, thread) }

  delegate :tenant, to: :box

  def note
    message_thread_note || build_message_thread_note
  end

  def messages_visible_to_user(user)
    messages.where(messages: { author_id: user.id }).or(messages.where(messages: { author_id: nil }))
  end

  def automation_rules_for_event(event)
    tenant.automation_rules.where(trigger_event: event)
  end

  def mark_all_messages_read
    messages.where(read: false).each do |message|
      message.read = true
      message.save!
    end
  end

  def self.merge_threads
    EventBus.publish(:message_threads_merged, all)
    transaction do
      target_thread = first
      all.each do |thread|
        thread.merge_thread_into(target_thread) if thread != target_thread
      end
      target_thread.message_thread_note&.save!
      target_thread.save!
    end
  end

  def merge_thread_into(target_thread)
    merge_identifiers.update_all(message_thread_id: target_thread.id)
    merge_dates(target_thread)
    messages.update_all(message_thread_id: target_thread.id)
    tags.each { |tag| target_thread.tags.push(tag) unless target_thread.tags.include?(tag) }
    merge_notes(target_thread)
    destroy!
  end

  def merge_dates(target_thread)
    target_thread.last_message_delivered_at = [target_thread.last_message_delivered_at,
                                               last_message_delivered_at].max
    target_thread.delivered_at = [target_thread.delivered_at, delivered_at].min
  end

  def merge_notes(target_thread)
    return unless message_thread_note&.note

    if target_thread.message_thread_note
      target_thread.message_thread_note.note = "#{target_thread.message_thread_note.note.rstrip}\n-----\n#{message_thread_note.note}"
    else
      target_thread.build_message_thread_note(note: message_thread_note.note)
    end
  end
end
