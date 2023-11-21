# == Schema Information
#
# Table name: messages
#
#  id                 :bigint           not null, primary key
#  collapsed          :boolean          default(FALSE), not null
#  delivered_at       :datetime         not null
#  html_visualization :text
#  metadata           :json
#  outbox             :boolean          default(FALSE), not null
#  read               :boolean          default(FALSE), not null
#  recipient_name     :string
#  replyable          :boolean          default(TRUE), not null
#  sender_name        :string
#  title              :string
#  type               :string
#  uuid               :uuid             not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  author_id          :bigint
#  import_id          :bigint
#  message_thread_id  :bigint           not null
#
class Message < ApplicationRecord
  belongs_to :thread, class_name: 'MessageThread', foreign_key: :message_thread_id
  belongs_to :author, class_name: 'User', foreign_key: :author_id, optional: true
  has_many :message_relations, dependent: :destroy
  has_many :message_relations_as_related_message, class_name: 'MessageRelation', foreign_key: :related_message_id, dependent: :destroy
  has_many :related_messages, through: :message_relations
  has_many :messages_tags, dependent: :destroy
  has_many :tags, through: :messages_tags
  has_many :objects, class_name: 'MessageObject', dependent: :destroy
  has_many :attachments, -> { where(object_type: "ATTACHMENT") }, class_name: 'MessageObject'
  # used for joins only
  has_many :message_threads_tags, primary_key: :message_thread_id, foreign_key: :message_thread_id

  delegate :tenant, to: :thread

  scope :outbox, -> { where(outbox: true) }
  scope :inbox, -> { where.not(outbox: true).where(type: nil).or(self.where.not(type: "MessageDraft")) }

  after_create_commit ->(message) { EventBus.publish(:message_created, message) }
  after_update_commit ->(message) { EventBus.publish(:message_changed, message) }
  after_destroy_commit ->(message) { EventBus.publish(:message_destroyed, message) }

  def automation_rules_for_event(event)
    tenant.automation_rules.where(trigger_event: event)
  end

  # TODO move to task/job in order to keep the domain clean
  def self.authorize_delivery_notification(message, schedule_sync: true)
    can_be_authorized = message.can_be_authorized?
    if can_be_authorized
      message.metadata["authorized"] = "in_progress"
      message.save!

      Govbox::AuthorizeDeliveryNotificationJob.perform_later(message, schedule_sync: schedule_sync)
    end

    can_be_authorized
  end

  def form
    objects.select { |o| o.form? }&.first
  end

  def collapsible?
    true
  end

  def visualizable_body?
    html_visualization.present? || (form && form.nested_message_objects.count > 1)
  end

  def can_be_authorized?
    metadata["delivery_notification"] && !metadata["authorized"] && Time.parse(metadata["delivery_notification"]["delivery_period_end_at"]) > Time.now
  end

  def authorized?
    metadata["delivery_notification"] && metadata["authorized"] == true
  end
end
