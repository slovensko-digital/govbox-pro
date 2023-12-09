class Notification < ApplicationRecord
  belongs_to :user, inverse_of: :notifications
  belongs_to :message_thread
  belongs_to :message
end
