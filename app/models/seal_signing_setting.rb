# == Schema Information
#
# Table name: seal_signing_settings
#
#  id                  :bigint           not null, primary key
#  certificate_subject :string
#  connection_sub      :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
class SealSigningSetting < ApplicationRecord
  has_one :tenant_signing_options, as: :signing_setting
end
