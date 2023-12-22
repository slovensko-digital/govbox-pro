# == Schema Information
#
# Table name: api_connections
#
#  id                    :bigint           not null, primary key
#  api_token_private_key :string           not null
#  obo                   :uuid
#  sub                   :string           not null
#  type                  :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
class Govbox::ApiConnection < ::ApiConnection
  def upvs_api(box)
    Upvs::GovboxApiClient.new.api(box)
  end

  def box_obo(box)
    raise "OBO not allowed!" if invalid_obo?(box)
    obo
  end

  def destroy_with_box?
    boxes.empty?
  end

  def validate_box(box)
    box.errors.add(:obo, :not_allowed) if invalid_obo?(box)
  end

  private

  def invalid_obo?(box)
    box.settings && box.settings["obo"].present?
  end
end
