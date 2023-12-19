# == Schema Information
#
# Table name: archived_objects
#
#  id                :bigint           not null, primary key
#  sgined_by         :string
#  signature_level   :string
#  signed_at         :datetime
#  validation_result :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  message_object_id :bigint           not null
#
class ArchivedObject < ApplicationRecord
  has_many :archived_object_versions
  belongs_to :message_object
end
