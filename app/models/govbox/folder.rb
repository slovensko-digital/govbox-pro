# == Schema Information
#
# Table name: govbox_folders
#
#  id                                          :integer          not null, primary key
#  edesk_folder_id                             :integer          not null
#  parent_folder_id                            :integer
#  box_id                                      :integer          not null
#  name                                        :string           not null
#  system                                      :boolean          not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Govbox::Folder < ApplicationRecord
  belongs_to :box
  belongs_to :parent_folder, class_name: 'Govbox::Folder', optional: true
  has_many :messages, class_name: 'Govbox::Message'

  def full_name
    if parent_folder_id.present?
      "#{parent_folder.full_name}/#{name}"
    else
      name
    end
  end

  def bin?
    name == "Bin"
  end
end
