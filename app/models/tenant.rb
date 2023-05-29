# == Schema Information
#
# Table name: tenants
#
#  id                                          :integer          not null, primary key
#  name                                        :string           not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Tenant < ApplicationRecord
  has_many :users
  has_many :boxes

  has_many :automation_rules, :class_name => 'Automation::Rule'
end
