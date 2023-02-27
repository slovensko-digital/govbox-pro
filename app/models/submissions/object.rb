# == Schema Information
#
# Table name: submission.objects
#
#  id                                          :integer          not null, primary key
#  submission_id                               :string           not null
#  uuid                                        :string           not null
#  name                                        :string           not null
#  signed                                      :boolean
#  to_be_signed                                :boolean
#  mime_type                                   :string           not null
#  form                                        :boolean
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Submissions::Object < ApplicationRecord
  self.table_name = 'submission.objects'

  belongs_to :submission, class_name: 'Submission'
end
