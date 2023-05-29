class Box < ApplicationRecord
  belongs_to :tenant

  has_many :folders
  has_many :message_threads, through: :folders, extend: MessageThreadsExtensions

  has_many :drafts_imports, class_name: 'Drafts::Import'
  has_many :drafts

  has_one :govbox_api_connection, class_name: 'Govbox::ApiConnection'
end

