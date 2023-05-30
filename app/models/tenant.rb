# == Schema Information
#
# Table name: tenants
#
#  id                                          :integer          not null, primary key
#  name                                        :string           not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Tenant < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :groups, dependent: :destroy

  has_one :all_group, -> { where(group_type: 'ALL') }, class_name: 'Group'

  has_many :boxes
  has_many :automation_rules, :class_name => 'Automation::Rule'

  after_create :create_default_groups

  validates_presence_of :name

  private

  def create_default_groups
    groups.create!(name: 'all', group_type: 'ALL')
    groups.create!(name: 'admins', group_type: 'ADMIN')
  end
end
