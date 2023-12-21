# == Schema Information
#
# Table name: archived_object_versions
#
#  id                 :bigint           not null, primary key
#  content            :binary           not null
#  valid_to           :datetime         not null
#  validation_result  :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  archived_object_id :bigint           not null
#
class ArchivedObjectVersion < ApplicationRecord
  belongs_to :archived_object
end
