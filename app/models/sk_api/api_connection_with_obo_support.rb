# == Schema Information
#
# Table name: api_connections
#
#  id                    :bigint           not null, primary key
#  api_token_private_key :string           not null
#  obo                   :uuid
#  settings              :jsonb
#  sub                   :string           not null
#  type                  :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  tenant_id             :bigint
#
class SkApi::ApiConnectionWithOboSupport < ::ApiConnection
  validates :tenant_id, presence: true

  def box_obo(box)
    raise "OBO not allowed!" if invalid_obo?(box)

    box.settings_obo.presence
  end

  def destroy_with_box?
    false
  end

  def validate_box(box)
    box.errors.add(:settings_obo, :not_allowed) if invalid_obo?(box)
    box.errors.add(:settings_obo, :invalid) if boxes.where.not(id: box.id).where("settings ->> 'obo' = ?", box.settings_obo).exists?
  end

  private

  def invalid_obo?(box)
    obo.present?
  end
end
