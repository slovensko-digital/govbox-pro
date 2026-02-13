# == Schema Information
#
# Table name: fs_form_attachment_groups
#
#  id         :bigint           not null, primary key
#  identifier :string           not null
#  mime_types :text             default([]), is an Array
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Fs::FormAttachmentGroup < ApplicationRecord
  has_many :attachments, class_name: "Fs::FormAttachment", foreign_key: "fs_form_attachment_group_id", dependent: :restrict_with_error

  validates :identifier, presence: true, uniqueness: true
end
