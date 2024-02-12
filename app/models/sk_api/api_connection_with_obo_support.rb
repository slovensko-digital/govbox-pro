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
#  tenant_id             :bigint
#
class SkApi::ApiConnectionWithOboSupport < ::ApiConnection
  validates :tenant_id, presence: true

  def upvs_api(box)
    Upvs::SkApiClient.new.api(box: box)
  end

  def box_obo(box)
    raise "OBO not allowed!" if box && invalid_obo?(box)

    box.settings["obo"] if box&.settings
    obo
  end

  def destroy_with_box?
    false
  end

  def validate_box(box)
    box.errors.add(:obo, :not_allowed) if invalid_obo?(box)
  end

  private

  def invalid_obo?(box)
    obo.present?
  end
end
