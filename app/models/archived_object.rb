# == Schema Information
#
# Table name: archived_objects
#
#  id                :integer          not null, primary key
#  message_object_id :integer          not null
#  validation_result :string           not null
#  signature_level   :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
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
