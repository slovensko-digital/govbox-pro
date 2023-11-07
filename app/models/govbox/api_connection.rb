# == Schema Information
#
# Table name: api_connections
#
#  id                                          :integer          not null, primary key
#  sub                                         :string           not null
#  obo                                         :uuid
#  api_token_private_key                       :string           not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Govbox::ApiConnection < ::ApiConnection
  def box_obo(box)
    raise "OBO not allowed!" if invalid_obo?(box)

    obo
  end

  def validate_box(box)
    box.errors.add(:obo, :not_allowed) if invalid_obo?(box)
  end

  private

  def invalid_obo?(box)
    box.settings && box.settings["obo"].present?
  end
end
