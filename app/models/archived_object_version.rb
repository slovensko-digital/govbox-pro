# == Schema Information
#
# Table name: archived_object_versions
#
#  id                 :integer          not null, primary key
#  archived_object_id :integer          not null
#  content            :binary           not null
#  validation_result  :string
#  valid_to           :datetime         not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class ArchivedObjectVersion < ApplicationRecord
  belongs_to :archived_object
end
