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

  has_one :all_group, class_name: "GroupAll"
  has_one :signer_group, class_name: "GroupSigner"
  has_one :admin_group, class_name: "GroupAdmin"
  has_many :custom_groups, class_name: "GroupCustom"

  has_many :boxes, dependent: :destroy
  has_many :automation_rules, class_name: "Automation::Rule", dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :filters
  after_create :create_default_objects

  validates_presence_of :name

  private

  def create_default_objects
    create_all_group!(name: "all")
    create_admin_group!(name: "admins")
    create_signer_group!(name: "Podpisovatelia")
    tags.create!(name: 'Drafty', system_name: Tag::DRAFT_SYSTEM_NAME, external: false, visible: true)
    tags.create!(name: 'Na prevzatie', system_name: 'delivery_notification', external: false, visible: true)
  end
end
