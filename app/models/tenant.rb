# == Schema Information
#
# Table name: tenants
#
#  id            :bigint           not null, primary key
#  feature_flags :string           default([]), is an Array
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

  has_one :draft_tag

  has_many :boxes, dependent: :destroy
  has_many :automation_rules, class_name: "Automation::Rule", dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :simple_tags
  has_many :filters
  after_create :create_default_objects

  validates_presence_of :name

  AVAILABLE_FEATURE_FLAGS = [:audit_log]

  def draft_tag!
    draft_tag || raise(ActiveRecord::RecordNotFound.new("`DraftTag` not found in tenant: #{self.id}"))
  end

  def feature_enabled?(feature)
    raise "Unknown feature #{feature}" unless feature.in? AVAILABLE_FEATURE_FLAGS

    feature.to_s.in? feature_flags
  end

  def enable_feature(feature)
    raise "Unknown feature #{feature}" unless feature.in? AVAILABLE_FEATURE_FLAGS
    raise "Feature already enabled" if feature.to_s.in? feature_flags

    feature_flags << feature
    save!
  end

  def disable_feature(feature)
    raise "Unknown feature #{feature}" unless feature.in? AVAILABLE_FEATURE_FLAGS
    raise "Feature not enabled" unless feature.to_s.in? feature_flags

    feature_flags.delete_if { |f| f == feature.to_s }
    save!
  end

  private

  def create_default_objects
    create_all_group!(name: "all")
    create_admin_group!(name: "admins")
    create_signer_group!(name: "signers")
    create_draft_tag!(name: "Rozpracované", visible: true)
  end
end
