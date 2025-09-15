# == Schema Information
#
# Table name: api_connections
#
#  id                    :bigint           not null, primary key
#  api_token_private_key :string           not null
#  custom_name           :string
#  obo                   :uuid
#  settings              :jsonb
#  sub                   :string           not null
#  type                  :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  owner_id              :bigint
#  tenant_id             :bigint
#
class Govbox::ApiConnectionWithOboSupport < ::ApiConnection
  validates :tenant_id, presence: true

  def box_obo(box)
    raise "OBO not allowed!" if obo.present?

    box.settings_obo.presence
  end

  def destroy_with_box?(box)
    false
  end

  def validate_box(box)
    box.errors.add(:settings_obo, :not_allowed) if obo.present?
    box.errors.add(:settings_obo, :invalid) if boxes.where.not(id: box.id).where("boxes.settings @> ?", { obo: box.settings_obo }.to_json).exists?
  end
end
