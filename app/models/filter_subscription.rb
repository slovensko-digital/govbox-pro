# == Schema Information
#
# Table name: filter_subscriptions
#
#  id         :bigint           not null, primary key
#  events     :string           not null, is an Array
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  filter_id  :bigint           not null
#  tenant_id  :bigint           not null
#  user_id    :bigint           not null
#
class FilterSubscription < ApplicationRecord
  belongs_to :tenant
  belongs_to :user
  belongs_to :filter

  def create_notification!(event, thing)
    case event
    when :message_created
      user.notifications.create!(type: Notifications::MessageCreated, message: thing, message_thread: thing.thread, happened_at: Time.current)
    else
      raise NotImplementedError, "Don't know how to handle #{event}"
    end

  end
end
