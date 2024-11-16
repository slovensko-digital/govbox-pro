# == Schema Information
#
# Table name: notifications
#
#  id                     :integer          not null, primary key
#  type                   :string           not null
#  user_id                :integer          not null
#  message_thread_id      :integer          not null
#  message_id             :integer
#  filter_subscription_id :integer
#  filter_name            :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class Notification < ApplicationRecord
  belongs_to :user, inverse_of: :notifications
  belongs_to :message_thread
  belongs_to :message, optional: true
  belongs_to :filter_subscription, optional: true

  delegate :filter, to: :filter_subscription
end
