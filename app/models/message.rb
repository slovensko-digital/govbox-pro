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
#  html_visualization                          :text             not null
#  delivered_at                                :datetime         not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Message < ApplicationRecord
  has_and_belongs_to_many :tags
  belongs_to :thread, class_name: 'MessageThread', foreign_key: 'message_thread_id'
  has_many :objects, class_name: 'MessageObject'
  delegate :tenant, to: :thread
  after_create_commit ->(message) { EventBus.publish(:message_created, message) }

  def automation_rules_for_event(event)
    tenant.automation_rules.where(trigger_event: event)
  end
end
