# == Schema Information
#
# Table name: signing_options
#
#  id         :bigint           not null, primary key
#  settings   :jsonb
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class SealSigningOption < SigningOption
  validate :validate_settings

  private

  def validate_settings
    errors.add(:settings, :invalid) unless settings["certificate_subject"].present?
    errors.add(:settings, :invalid) unless settings["api_connection_id"].present?
  end
end
