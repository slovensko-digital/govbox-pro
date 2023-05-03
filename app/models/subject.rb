# == Schema Information
#
# Table name: subjects
#
#  id                                          :integer          not null, primary key
#  name                                        :string           not null
#  uri                                         :string           not null
#  sub                                         :string           not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Subject < ApplicationRecord
  has_many :drafts_imports, class_name: 'Drafts::Import'
  has_many :drafts
end
