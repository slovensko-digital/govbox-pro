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

  end
end
