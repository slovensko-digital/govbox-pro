# == Schema Information
#
# Table name: fs_form_attachments
#
#  id                          :bigint           not null, primary key
#  max_occurrences             :integer          default(99), not null
#  min_occurrences             :integer          default(0), not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  fs_form_attachment_group_id :bigint           not null
#  fs_form_id                  :bigint           not null
#
class Fs::FormAttachment < ApplicationRecord
  belongs_to :form, class_name: "Fs::Form", foreign_key: "fs_form_id"
  belongs_to :group, class_name: "Fs::FormAttachmentGroup", foreign_key: "fs_form_attachment_group_id"

  delegate :document_type_identifier, :name, to: :group
end
