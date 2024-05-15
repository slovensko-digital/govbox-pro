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
class Fs::ApiConnection < ::ApiConnection
  validates :tenant_id, presence: true
  encrypts :settings

  store_accessor :settings, :username, prefix: true
  store_accessor :settings, :password, prefix: true

  def box_obo(box)
    raise "OBO not allowed!" if invalid_obo?(box)
    obo.presence
  end

  def destroy_with_box?
    false
  end

  def validate_box(box)
    box.errors.add(:settings_obo, :not_allowed) if invalid_obo?(box)
  end

  def editable?
    true
  end

  def destroyable?
    true
  end

  def fs_type?
    true
  end

  def upvs_type?
    false
  end

  private

  def invalid_obo?(box)
    box.settings && box.settings["obo"].present?
  end
end
