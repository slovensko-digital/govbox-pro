# == Schema Information
#
# Table name: drafts_packages
#
#  id                                          :integer          not null, primary key
#  name                                        :string           not null
#  box_id                                      :integer          not null
#  content_path                                :string           not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Drafts::Import < ApplicationRecord
  belongs_to :box, class_name: 'Box'
  has_many :drafts, :dependent => :destroy

  validates_with DraftsImportValidator, if: :content_path

  enum status: { uploaded: 0, parsed: 1, parsing_failed: 2 }

  def base_name
    name.split('_', 2).last
  end
end
