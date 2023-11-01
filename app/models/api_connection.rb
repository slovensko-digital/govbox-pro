# == Schema Information
#
# Table name: api_connections
#
#  id                                          :integer          not null, primary key
#  sub                                         :string           not null
#  api_token_private_key                       :string           not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class ApiConnection < ApplicationRecord
  belongs_to :box
end
