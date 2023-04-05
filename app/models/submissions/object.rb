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
#  content                                     :binary           not null
#  form                                        :boolean
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Submissions::Object < ApplicationRecord
  self.table_name = 'submission.objects'

  belongs_to :submission, class_name: 'Submission'

  def is_valid?
    valid_mime_type?
  end

  def validation_errors
    errors = []

    unless valid_mime_type?
      errors << "Nepovolený formát súboru #{name}. Povolené formáty sú: #{Utils::EXTENSIONS_ALLOW_LIST.join(', ')}."
    end
  end

  private

  def valid_mime_type?
    Utils.detect_mime_type(self)
  rescue StandardError
    false
  end
end
