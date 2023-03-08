# == Schema Information
#
# Table name: submissions
#
#  id                                          :integer          not null, primary key
#  package_id                                  :integer          not null
#  status                                      :integer          default("created"), not null
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

  has_many :objects, class_name: 'Submissions::Object'

  delegate :subject, :to => :package, :allow_nil => false

  enum status: { created: 0, being_submitted: 1, submitted: 2 }

  def form
    objects.select { |o| o.form? }&.first
  end

  def has_one_form?
    objects.select { |o| o.form? }.count == 1
  end
end
