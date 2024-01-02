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
class Govbox::ApiConnectionWithOboSupport < ::ApiConnection
  validates :tenant_id, presence: true

  def upvs_api(box)
    Upvs::GovboxApiClient.new.api(box)
  end

  def box_obo(box)
    raise "OBO not allowed!" if obo.present?

    box.settings_obo
  end

  def destroy_with_box?
    false
  end

  def validate_box(box)
    box.errors.add(:obo, :not_allowed) if obo.present?
    if tenant
      box.errors.add(:settings_obo, :blank) if box.settings_obo.blank?
    end
  end
end
