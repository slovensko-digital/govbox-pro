# == Schema Information
#
# Table name: autogram_signing_settings
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class AutogramSigningSetting < ApplicationRecord
  has_one :tenant_signing_options, as: :signing_setting
end
