# == Schema Information
#
# Table name: archived_objects
#
#  id                :bigint           not null, primary key
#  signature_level   :string
#  validation_result :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  message_object_id :bigint           not null
#
class ArchivedObject < ApplicationRecord
  has_many :archived_object_versions
  belongs_to :message_object

  def valid_signature?
    validation_result == '0'
  end

  def content
    return nil unless archived?

    archived_object_versions.last.content
  end

  def archived?
    !archived_object_versions.empty?
  end

  def needs_extension?
    archived_object_versions.empty? || needs_renewal?
  end

  def signed?
    validation_result != '-1'
  end

  private

  def needs_renewal?
    archived_object_versions.last.valid_to < 90.days.ago
  end
end
