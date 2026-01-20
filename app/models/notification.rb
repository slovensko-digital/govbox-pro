# == Schema Information
#
# Table name: notifications
#
#  id                     :bigint           not null, primary key
#  filter_name            :string
#  type                   :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  export_id              :bigint
#  filter_subscription_id :bigint
#  message_id             :bigint
#  message_thread_id      :bigint
#  user_id                :bigint           not null
#
class Notification < ApplicationRecord
  belongs_to :user, inverse_of: :notifications
  belongs_to :message_thread, optional: true
  belongs_to :message, optional: true
  belongs_to :filter_subscription, optional: true
  belongs_to :export, optional: true

  delegate :filter, to: :filter_subscription

  after_create -> { user.update(notifications_opened: false) }
end
