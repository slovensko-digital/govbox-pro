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

  enum status: { being_loaded: 0, created: 1, corrupt: 2, being_submitted: 3, submitted: 4, submit_failed: 5 }

  def submitted?
    status == 'submitted'
  end

  def submittable?
    (status == 'created' || 'submit_failed') && valid_for_submission?
  end

  def form
    objects.select { |o| o.form? }&.first
  end

  def has_one_form?
    objects.select { |o| o.form? }.count == 1
  end

  def valid_for_submission?
    has_one_form?
  end
end
