# == Schema Information
#
# Table name: tenants
#
#  id                                          :integer          not null, primary key
#  name                                        :string           not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Tenant < ApplicationRecord
  has_many :subjects
  has_many :users
end
