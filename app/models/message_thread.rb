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
  has_many :objects, through: :messages

  validates :title, presence: true

  attr_accessor :search_highlight

  after_create_commit ->(thread) { thread.tags << thread.tenant.everything_tag }
  after_update_commit ->(thread) { EventBus.publish(:message_thread_changed, thread) }

  delegate :tenant, to: :box

  def note
    message_thread_note || build_message_thread_note
  end

  def automation_rules_for_event(event)
    tenant.automation_rules.where(trigger_event: event)
  end

  def archived?
    # TODO find a way how not to fire query every time this method is called
    tags.exists?(type: ArchivedTag.to_s)
  end

  def archive(value)
    return unless value != archived?

    if value
      tags << tenant.tags.find_by(type: ArchivedTag.to_s)
      Archivation::ArchiveMessageThreadJob.perform_later(self)
      EventBus.publish(:message_thread_archive_on, self)
    else
      tags.delete(tags.find_by(type: ArchivedTag.to_s))
      EventBus.publish(:message_thread_archive_off, self)
    end
  end

  def rename(params)
    result = update(params)
    EventBus.publish(:message_thread_renamed, self)
    result
  end

  def mark_all_messages_read
    messages.where(read: false).each do |message|
      message.read = true
      message.save!
    end
  end

  def self.merge_threads
    return unless all.map(&:box).uniq.count == 1

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

  def mark_signed_by_user(user)
    # user_signed_tag
    unless has_tag_in_message_objects?(user.signature_requested_from_tag)
      assign_tag(user.signed_by_tag)
      unassign_tag(user.signature_requested_from_tag)
      unassign_tag(user.tenant.signer_group.signature_requested_from_tag) unless has_tag_in_message_objects?({ id: user.tenant.signer_group.signature_requested_from_tag.id })
    end

    # signed_tag
    unless has_tag_in_message_objects?({ type: SignatureRequestedFromTag.to_s })
      assign_tag(user.tenant.signed_tag)
      unassign_tag(user.tenant.signature_requested_tag)
    end
  end

  def add_signature_requested_from_group(group)
    # user_signature_requested_tag
    assign_tag(group.signature_requested_from_tag)
    unassign_tag(group.signed_by_tag)

    # signature_requested_tag
    assign_tag(group.tenant.signature_requested_tag)
    unassign_tag(group.tenant.signed_tag)
  end

  def remove_signature_requested_from_group(group)
    # user_signature_requested_tag
    unless has_tag_in_message_objects?(group.signature_requested_from_tag)
      unassign_tag(group.signature_requested_from_tag)

      if has_tag_in_message_objects?(group.signed_by_tag)
        assign_tag(group.signed_by_tag)
      end
    end

    # signature_requested_tag
    unless has_tag_in_message_objects?({ type: SignatureRequestedFromTag.to_s })
      unassign_tag(group.tenant.signature_requested_tag)

      if has_tag_in_message_objects?({ type: SignedByTag.to_s })
        assign_tag(group.tenant.signed_tag)
      end
    end
  end

  def assign_tag(tag)
    message_threads_tags.find_or_create_by!(tag: tag)
  end

  def unassign_tag(tag)
    message_threads_tags.find_by(tag: tag)&.destroy
  end

  private

  def has_tag?(tag)
    message_threads_tags.joins(:tag).where(tag: tag).exists?
  end

  def has_tag_in_message_objects?(tag)
    objects.joins(:tags).where(tags: tag).exists?
  end
end
