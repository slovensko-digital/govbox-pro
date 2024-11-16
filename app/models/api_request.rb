# == Schema Information
#
# Table name: api_requests
#
#  id                 :integer          not null, primary key
#  endpoint_path      :string           not null
#  endpoint_method    :string           not null
#  response_status    :integer          not null
#  authenticity_token :string           not null
#  ip_address         :inet
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class ApiRequest < ApplicationRecord
end
