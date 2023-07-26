# == Schema Information
#
# Table name: messages
#
#  id                                          :integer          not null, primary key
#  uuid                                        :uuid             not null
#  title                                       :string           not null
#  message_thread_id                           :integer          not null
#  sender_name                                 :string
#  recipient_name                              :string
#  html_visualization                          :text
#  metadata                                    :json
#  read                                        :boolean          not null, default: false
#  delivered_at                                :datetime         not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Message < ApplicationRecord
  has_and_belongs_to_many :tags
  belongs_to :thread, class_name: 'MessageThread', foreign_key: 'message_thread_id'
  has_many :objects, class_name: 'MessageObject', dependent: :destroy
  delegate :tenant, to: :thread
  after_create_commit ->(message) { EventBus.publish(:message_created, message) }

  DELIVERY_NOTIFICATION_CLASS = 'ED_DELIVERY_NOTIFICATION'
  EGOV_DOCUMENT_CLASS = 'EGOV_DOCUMENT'
  EGOV_NOTIFICATION_CLASS = 'EGOV_NOTIFICATION'

  def automation_rules_for_event(event)
    tenant.automation_rules.where(trigger_event: event)
  end

  def can_be_replied?
    tags.where("name LIKE ?", "#{"slovensko.sk:Inbox%"}").present? && (egov_document? || egov_notification?)
  end

  def delivery_notification?
    metadata["edesk_class"] == DELIVERY_NOTIFICATION_CLASS
  end

  private

  def egov_document?
    metadata["edesk_class"] == EGOV_DOCUMENT_CLASS
  end

  def egov_notification?
    metadata["edesk_class"] == EGOV_NOTIFICATION_CLASS
  end
end
