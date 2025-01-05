# == Schema Information
#
# Table name: govbox_folders
#
#  id               :bigint           not null, primary key
#  name             :string           not null
#  settings         :jsonb
#  system           :boolean          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  box_id           :bigint           not null
#  edesk_folder_id  :integer          not null
#  parent_folder_id :bigint
#
class Govbox::Folder < ApplicationRecord
  belongs_to :box
  belongs_to :parent_folder, class_name: 'Govbox::Folder', dependent: :destroy, optional: true
  has_many :messages, class_name: 'Govbox::Message', dependent: :destroy
  has_many :child_folders, class_name: 'Govbox::Folder', foreign_key: :parent_folder_id, dependent: :destroy

  def full_name
    parent_folder_id.present? ? "#{parent_folder.full_name}/#{name}" : name
  end

  def inbox?
    name.start_with? 'Inbox'
  end

  def outbox?
    name.start_with? 'SentItems'
  end

  def bin?
    name == 'Bin'
  end

  def drafts?
    name.start_with? 'Drafts'
  end
end
