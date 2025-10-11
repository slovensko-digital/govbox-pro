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
        filter_name: subscription.filter.name
      )
      url = Rails.application.routes.url_helpers.message_thread_url(thread)
      WebpushJob.perform_now(I18n.t("filter_subscription.events.Notifications::NewMessageThread.name"), thread.title, message_thread_url(thread), subscription.user)
    end
  end
end
