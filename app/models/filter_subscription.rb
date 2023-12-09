class FilterSubscription < ApplicationRecord
  belongs_to :user
  belongs_to :filter

  def matches_message_thread?

  end
end
