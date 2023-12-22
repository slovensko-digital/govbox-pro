# == Schema Information
#
# Table name: tenant_signing_options
#
#  id                :bigint           not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  signing_option_id :bigint           not null
#  tenant_id         :bigint           not null
#
class TenantSigningOption < ApplicationRecord
  belongs_to :tenant
  belongs_to :signing_option
end
