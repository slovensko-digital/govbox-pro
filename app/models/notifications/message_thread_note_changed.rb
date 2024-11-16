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
