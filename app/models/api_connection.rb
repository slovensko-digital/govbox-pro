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
class ApiConnection < ApplicationRecord
  belongs_to :tenant, optional: true
  has_many :boxes

  def box_obo(box)
    raise NotImplementedError
  end

  def destroy_with_box?
    raise NotImplementedError
  end

  def validate_box(box)
    raise NotImplementedError
  end

  def name
    custom_name || "#{type} - #{sub}"
  end

  def editable?
    false
  end

  def destroyable?
    false
  end

  def upvs_type?
    true
  end

  def fs_type?
    false
  end

  private

  def invalid_obo?(box)
    raise NotImplementedError
  end
end
