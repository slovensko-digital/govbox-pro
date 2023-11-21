# == Schema Information
#
# Table name: message_drafts_imports
#
#  id           :bigint           not null, primary key
#  content_path :string
#  name         :string           not null
#  status       :integer          default("uploaded")
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  box_id       :bigint           not null
#
class MessageDraftsImport < ApplicationRecord
  belongs_to :box, class_name: 'Box'
  has_many :message_drafts, foreign_key: :import_id, dependent: :destroy

  validates_with MessageDraftsImportValidator, if: :unzipped?

  enum status: { uploaded: 0, unzipped: 1, parsed: 2 }

  def base_name
    name.split('_', 2).last
  end
end
