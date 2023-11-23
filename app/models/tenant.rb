# == Schema Information
#
# Table name: tenants
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Tenant < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :groups, dependent: :destroy

  has_one :all_group, -> { where(group_type: 'ALL') }, class_name: 'Group'
  has_many :admin_groups, -> { where(group_type: 'ADMIN') }, class_name: 'Group'

  has_many :boxes, dependent: :destroy
  has_many :automation_rules, class_name: 'Automation::Rule', dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :filters
  after_create :create_default_objects

  validates_presence_of :name

  private

  def create_default_objects
    groups.create!(name: 'all', group_type: 'ALL')
    groups.create!(name: 'admins', group_type: 'ADMIN')
    tags.create!(name: 'Drafty', system_name: Tag::DRAFT_SYSTEM_NAME, external: false, visible: true)
    tags.create!(name: 'Na prevzatie', system_name: 'delivery_notification', external: false, visible: true)
  end
end
