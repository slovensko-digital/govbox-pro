# == Schema Information
#
# Table name: signing_options
#
#  id         :bigint           not null, primary key
#  settings   :jsonb
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  tenant_id  :bigint           not null
#
class SigningOption < ApplicationRecord
  belongs_to :tenant
end
