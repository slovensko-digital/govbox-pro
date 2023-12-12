# == Schema Information
#
# Table name: notifications
#
#  id                :bigint           not null, primary key
#  happened_at       :datetime         not null
#  type              :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  message_id        :bigint
#  message_thread_id :bigint           not null
#  user_id           :bigint           not null
#
class Notification < ApplicationRecord
  belongs_to :user, inverse_of: :notifications
  belongs_to :message_thread
  belongs_to :message
end
