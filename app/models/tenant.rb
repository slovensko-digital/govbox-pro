# == Schema Information
#
# Table name: tenants
#
#  id            :bigint           not null, primary key
#  feature_flags :jsonb
#  name          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class Tenant < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :groups, dependent: :destroy

  has_one :all_group
  has_one :signer_group
  has_one :admin_group
  has_many :custom_groups

  has_many :boxes, dependent: :destroy
  has_many :automation_rules, class_name: "Automation::Rule", dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :filters
  after_create :create_default_objects

  validates_presence_of :name

  AVAILABLE_FEATURE_FLAGS = [:audit_log]

  def feature_enabled?(feature)
    raise "Unknown feature #{feature}" unless feature.in? AVAILABLE_FEATURE_FLAGS

    feature_flags[feature.to_s] == true
  end

  def enable_feature(feature)
    raise "Unknown feature #{feature}" unless feature.in? AVAILABLE_FEATURE_FLAGS

    current_flags = feature_flags
    update(feature_flags: current_flags.merge({ feature => true }))
  end

  def disable_feature(feature)
    raise "Unknown feature #{feature}" unless feature.in? AVAILABLE_FEATURE_FLAGS

    current_flags = feature_flags
    update(feature_flags: current_flags.merge({ feature => false }))
  end

  private

  def create_default_objects
    create_all_group!(name: "all")
    create_admin_group!(name: "admins")
    create_signer_group!(name: "signers")
    tags.create!(name: 'Drafty', system_name: Tag::DRAFT_SYSTEM_NAME, external: false, visible: true)
    tags.create!(name: 'Na prevzatie', system_name: 'delivery_notification', external: false, visible: true)
  end
end
