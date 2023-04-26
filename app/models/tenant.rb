# == Schema Information
#
# Table name: tenants
#
#  id                                          :integer          not null, primary key
#  name                                        :string           not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Tenant < ApplicationRecord
end
