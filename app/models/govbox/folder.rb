# == Schema Information
#
# Table name: govbox_folders
#
#  id                                          :integer          not null, primary key
#  edesk_folder_id                             :integer          not null
#  box_id                                      :integer          not null
#  name                                        :string           not null
#  system                                      :boolean          not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Govbox::Folder < ApplicationRecord
  belongs_to :box
  has_many :messages, class_name: 'Govbox::Message'
end
