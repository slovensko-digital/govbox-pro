# == Schema Information
#
# Table name: notifications
#
#  id                     :bigint           not null, primary key
#  filter_name            :string           not null
#  type                   :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  filter_subscription_id :bigint
#  message_id             :bigint
#  message_thread_id      :bigint           not null
#  user_id                :bigint           not null
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
