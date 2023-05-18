class Folder < ApplicationRecord
  belongs_to :box
  has_many :message_threads

  delegate :tenant, to: :box
end
