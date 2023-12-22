# == Schema Information
#
# Table name: tenant_signing_options
#
#  id                   :bigint           not null, primary key
#  signing_setting_type :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  signing_setting_id   :bigint
#  tenant_id            :bigint           not null
#
class TenantSigningOption < ApplicationRecord
  belongs_to :tenant
  belongs_to :signing_setting, polymorphic: true
end
