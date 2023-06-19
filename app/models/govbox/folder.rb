# == Schema Information
#
# Table name: govbox_folders
#
#  id                                          :integer          not null, primary key
#  edesk_folder_id                             :integer          not null
#  edesk_parent_folder_id                      :integer          not null
#  box_id                                      :integer          not null
#  name                                        :string           not null
#  system                                      :boolean          not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Govbox::Folder < ApplicationRecord
  belongs_to :box
  has_many :messages, class_name: 'Govbox::Message'

  def full_name
    if edesk_parent_folder_id.present?
      "#{Govbox::Folder.find_by(edesk_folder_id: edesk_parent_folder_id).full_name}/#{name}"
    else
      name
    end
  end
end
