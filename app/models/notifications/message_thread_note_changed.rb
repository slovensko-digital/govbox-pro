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

    def send_webpush
      return unless sends_webpush?

      url = Rails.application.routes.url_helpers.message_thread_url(message_thread)
      WebpushJob.perform_later(I18n.t("filter_subscription.events.Notifications::MessageThreadNoteChanged.name"), message_thread.title, url, user)
    end
  end
end
