class Box < ApplicationRecord
  belongs_to :tenant

  has_many :folders
  has_many :message_threads, through: :folders, extend: MessageThreadsExtensions
end

