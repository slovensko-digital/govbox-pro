# == Schema Information
#
# Table name: submissions_packages
#
#  id                                          :integer          not null, primary key
#  name                                        :string           not null
#  subject_id                                  :integer          not null
#  content_path                                :string           not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Submissions::Package < ApplicationRecord
  belongs_to :subject, class_name: 'Subject'
  has_many :submissions, :dependent => :destroy

  validates_with SubmissionPackageValidator, if: :content_path

  enum status: { uploaded: 0, parsed: 1, parsing_failed: 2 }

  def base_name
    name.split('_', 2).last
  end
end
