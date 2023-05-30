# == Schema Information
#
# Table name: boxes
#
#  id                                          :integer          not null, primary key
#  name                                        :string           not null
#  uri                                         :string
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Box < ApplicationRecord
  belongs_to :tenant

  has_many :folders
  has_many :message_threads, through: :folders, extend: MessageThreadsExtensions

  has_many :govbox_folders, class_name: 'Govbox::Folder'
  has_many :govbox_messages, through: :govbox_folders

  has_many :drafts_imports, class_name: 'Drafts::Import'
  has_many :drafts

  has_one :govbox_api_connection, class_name: 'Govbox::ApiConnection'
end

