class MessageObject < ApplicationRecord
  belongs_to :message
  has_one :message_object_datum
end
