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
    "#{type} - #{sub}"
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
