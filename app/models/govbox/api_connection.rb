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
