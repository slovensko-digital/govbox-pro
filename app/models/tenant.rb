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
  has_many :users, dependent: :destroy
  has_many :groups, dependent: :destroy

  after_create :create_default_groups

  private

  def create_default_groups
    groups.create!(name: 'All Tenant users - default system group', group_type: 'ALL')
    groups.create!(name: 'Tenant admins - default system group', group_type: 'ADMIN')
  end
end
