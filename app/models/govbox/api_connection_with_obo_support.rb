# == Schema Information
#
# Table name: api_connections
#
#  id                    :integer          not null, primary key
#  sub                   :string           not null
#  obo                   :uuid
#  api_token_private_key :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  type                  :string
#  tenant_id             :integer
#  settings              :jsonb
#

class Govbox::ApiConnectionWithOboSupport < ::ApiConnection
  validates :tenant_id, presence: true

  def box_obo(box)
    raise "OBO not allowed!" if obo.present?

    box.settings_obo.presence
  end

  def destroy_with_box?
    false
  end

  def validate_box(box)
    box.errors.add(:settings_obo, :not_allowed) if obo.present?
    box.errors.add(:settings_obo, :invalid) if boxes.where.not(id: box.id).where("settings @> ?", { obo: box.settings_obo }.to_json).exists?
  end
end
