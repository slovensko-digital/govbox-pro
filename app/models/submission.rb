# == Schema Information
#
# Table name: submissions
#
#  id                                          :integer          not null, primary key
#  subject_id                                  :integer
#  package_id                                  :integer
#  status                                      :integer          default("created")
#  recipient_uri                               :string
#  posp_id                                     :string
#  posp_version                                :string
#  message_type                                :string
#  message_subject                             :string
#  sender_business_reference                   :string
#  recipient_business_reference                :string
#  package_subfolder                           :string
#  message_id                                  :uuid
#  correlation_id                              :uuid
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Submission < ApplicationRecord
  belongs_to :subject
  belongs_to :package, class_name: 'Submissions::Package', optional: true

  has_many :objects, class_name: 'Submissions::Object', :dependent => :destroy

  with_options on: :validate_data do |loaded_submission|
    loaded_submission.validates :recipient_uri, :posp_id, :posp_version, :message_type, :message_subject, :message_id, :correlation_id, presence: true
    loaded_submission.validates :message_id, :correlation_id, format: { with: Utils::UUID_PATTERN }, allow_blank: true
    loaded_submission.validate :has_one_form?
    loaded_submission.validate :validate_objects
  end

  enum status: { created: 0, being_loaded: 1, loading_done: 2, invalid_data: 3, being_submitted: 4, submitted: 5, submit_failed_unprocessable: 6, submit_failed_temporary: 7 }

  def title
    message_subject || package_subfolder
  end

  def submittable?
    (loading_done? || submit_failed_temporary?) && valid?
  end

  def form
    objects.select { |o| o.form? }&.first
  end

  private

  def has_one_form?
    forms = objects.select { |o| o.form? }

    if objects.size == 0
      errors.add(:objects, "No objects found for submission")
    elsif forms.count != 1
      errors.add(:objects, "Submission has to contain exactly one form")
    end
  end

  def validate_objects
    objects.each do |object|
      object.valid?(:validate_data)
      errors.merge!(object.errors)
    end
  end
end
