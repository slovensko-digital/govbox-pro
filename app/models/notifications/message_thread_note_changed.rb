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
  class MessageThreadNoteChanged < ::Notification
    def self.create_notifications!(subscription, thread, _)
      return unless thread.message_thread_note
      return unless thread.message_thread_note.updated_at > subscription.last_notify_run_at

      subscription.user.notifications.create!(
        type: Notifications::MessageThreadNoteChanged,
        message_thread: thread,
        filter_subscription: subscription,
        filter_name: subscription.filter.name
      )
    end
  end
end
