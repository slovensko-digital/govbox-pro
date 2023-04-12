# == Schema Information
#
# Table name: submissions
#
#  id                                          :integer          not null, primary key
#  package_id                                  :integer          not null
#  status                                      :integer          default("being_loaded"), not null
#  recipient_uri                               :string           not null
#  posp_id                                     :string           not null
#  posp_version                                :string           not null
#  message_type                                :string           not null
#  message_subject                             :string           not null
#  sender_business_reference                   :string
#  recipient_business_reference                :string
#  package_subfolder                           :string
#  message_id                                  :uuid             not null
#  correlation_id                              :uuid             not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Submission < ApplicationRecord
  belongs_to :package, class_name: 'Submissions::Package'

  has_many :objects, class_name: 'Submissions::Object', :dependent => :destroy

  delegate :subject, :to => :package, :allow_nil => false

  enum status: { created: 0, being_loaded: 1, loading_done: 2, being_submitted: 3, submitted: 4, submit_failed: 5 }

  def title
    message_subject || package_subfolder
  end

  def submittable?
    (loading_done? || submit_failed?) && is_valid?
  end

  def form
    objects.select { |o| o.form? }&.first
  end

  def is_valid?
    loading_done? && all_mandatory_data_present? && has_one_form? && all_objects_valid?
  end

  def validation_errors
    errors = []

    unless all_mandatory_data_present?
      missing_attributes = mandatory_attributes.select { |_, v| v.blank? }
      errors << "Chýbajúce dáta v CSV prehľade o podaní: #{missing_attributes.keys.join(", ")}"
    end

    if objects.size == 0
      errors << "K podaniu nebol nájdený formulár, ani žiadna príloha"
    elsif !has_one_form?
      errors << "Podanie musí obsahovať práve jeden formulár!"
    end

    unless all_objects_valid?
      errors += objects.map { |object| object.validation_errors }.compact.flatten
    end

    errors
  end

  private

  def has_one_form?
    objects.select { |o| o.form? }.count == 1
  end

  def mandatory_attributes
    attributes.slice("recipient_uri", "posp_id", "posp_version", "message_type", "message_subject")
  end

  def all_mandatory_data_present?
    mandatory_attributes.all? { |_, v| v.present? }
  end

  def all_objects_valid?
    objects.all? { |object| object.is_valid? }
  end
end
