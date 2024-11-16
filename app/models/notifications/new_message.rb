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
  class NewMessage < ::Notification
    def self.create_notifications!(subscription, thread, _)
      new_messages = thread.messages.where("created_at > ?", subscription.last_notify_run_at)

      new_messages.find_each do |message|
        next if message.draft?

        subscription.user.notifications.create!(
          type: Notifications::NewMessage,
          message_thread: thread,
          message: message,
          filter_subscription: subscription,
          filter_name: subscription.filter.name
        )
      end
    end
  end
end
