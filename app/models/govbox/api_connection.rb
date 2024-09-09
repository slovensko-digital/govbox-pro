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
class Govbox::ApiConnection < ::ApiConnection
  validates :tenant_id, absence: true

  def box_obo(box)
    raise "OBO not allowed!" if invalid_obo?(box)
    obo.presence
  end

  def destroy_with_box?
    boxes.empty?
  end

  def validate_box(box)
    box.errors.add(:settings_obo, :not_allowed) if invalid_obo?(box)
  end

  private

  def invalid_obo?(box)
    box.settings && box.settings_obo.present?
  end
end
