class Message < ApplicationRecord
  belongs_to :message_thread # TODO rename
  has_many :message_objects # TODO rename
end
