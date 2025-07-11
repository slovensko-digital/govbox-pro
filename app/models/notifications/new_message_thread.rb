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
