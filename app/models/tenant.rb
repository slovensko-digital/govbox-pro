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

  has_one :all_group
  has_one :signer_group
  has_one :admin_group
  has_many :groups, dependent: :destroy
  has_many :custom_groups

  has_many :signing_options, dependent: :destroy

  has_one :draft_tag
  has_one :everything_tag
  has_one :signature_requested_tag
  has_one :signed_tag
  has_many :tags, dependent: :destroy
  has_many :signature_requested_from_tags
  has_many :signed_by_tags
  has_many :simple_tags
  has_one :archived_tag

  has_many :boxes, dependent: :destroy
  has_many :automation_rules, class_name: "Automation::Rule", dependent: :destroy
  has_many :filters

  has_many :filter_subscriptions

  after_create :create_default_objects

  validates_presence_of :name

  AVAILABLE_FEATURE_FLAGS = [:audit_log, :archive]

  def draft_tag!
    draft_tag || raise(ActiveRecord::RecordNotFound.new("`DraftTag` not found in tenant: #{self.id}"))
  end

  def signature_requested_tag!
    signature_requested_tag || raise(ActiveRecord::RecordNotFound.new("`SignatureRequestedTag` not found in tenant: #{self.id}"))
  end

  def signed_tag!
    signed_tag || raise(ActiveRecord::RecordNotFound.new("`SignatureRequestedTag` not found in tenant: #{self.id}"))
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

  def make_admins_see_everything!
    everything_tag.groups << admin_group
  end

  private

  def create_default_objects
    create_all_group!(name: "all")
    create_admin_group!(name: "admins")
    create_signer_group!(name: "signers")

    create_draft_tag!(name: "Rozpracované", visible: true)
    create_everything_tag!(name: "Všetky správy", visible: false)
    create_signature_requested_tag!(name: "Na podpis", visible: true, color: "yellow", icon: "pencil")
    create_signed_tag!(name: "Podpísané", visible: true, color: "green", icon: "fingerprint")

    make_admins_see_everything!

    create_default_signing_options!
  end

  def create_default_signing_options!
    signing_options.create!(
      type: 'AutogramSigningOption',
    )
  end
end
