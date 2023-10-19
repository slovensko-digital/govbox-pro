# == Schema Information
#
# Table name: upvs_api_connections
#
#  id                                          :integer          not null, primary key
#  sub                                         :string           not null
#  api_token_private_key                       :string           not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Govbox::ApiConnectionWithOboSupport < ::Upvs::ApiConnection
end
