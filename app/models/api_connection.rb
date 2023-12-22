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
class ApiConnection < ApplicationRecord
  has_many :boxes

  def upvs_api(box)
    raise NotImplementedError
  end

  def box_obo(box)
    raise NotImplementedError
  end

  def destroy_with_box?
    raise NotImplementedError
  end

  def validate_box(box)
    raise NotImplementedError
  end

  private

  def invalid_obo?(box)
    raise NotImplementedError
  end
end
