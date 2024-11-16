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

module Notifications
  class NewMessageThread < ::Notification
    def self.create_notifications!(subscription, thread, matched_before)
      return if matched_before

      subscription.user.notifications.create!(
        type: Notifications::NewMessageThread,
        message_thread: thread,
        filter_subscription: subscription,
        filter_name: subscription.filter.name,
      )
    end
  end
end
