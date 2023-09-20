# == Schema Information
#
# Table name: govbox_api_connections
#
#  id                                          :integer          not null, primary key
#  sub                                         :string           not null
#  obo                                         :uuid
#  box_id                                      :integer          not null
#  api_token_private_key                       :string           not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Govbox::ApiConnection < ApplicationRecord
end
