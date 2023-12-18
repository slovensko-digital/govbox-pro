# == Schema Information
#
# Table name: api_requests
#
#  id                 :bigint           not null, primary key
#  authenticity_token :string           not null
#  endpoint_method    :string           not null
#  endpoint_path      :string           not null
#  ip_address         :inet
#  response_status    :integer          not null
#  type               :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
class ApiRequest < ApplicationRecord
  class ProvidedApiRequest < ApiRequest
  end

  class ConsumedApiRequest < ApiRequest
  end
end
