# == Schema Information
#
# Table name: submission.packages
#
#  id                                          :integer          not null, primary key
#  name                                        :string           not null
#  subject_id                                  :integer          not null
#  content                                     :binary           not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Submissions::Package < ApplicationRecord
  self.table_name = 'submission.packages'

  belongs_to :subject, class_name: 'Subject'
  has_many :submissions, :dependent => :destroy

  enum status: { uploaded: 0, parsed: 1, parsing_failed: 2 }

  def base_name
    name.split('_', 2).last
  end

  def submittable?
    status == 'parsed' && submissions.all? { |submission| submission.status == 'created' || submission.status == 'submit_failed' }
  end
end
