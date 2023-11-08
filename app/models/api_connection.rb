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

class ApiConnection < ApplicationRecord
  has_many :boxes

  def box_obo(box)
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
