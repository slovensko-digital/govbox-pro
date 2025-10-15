# == Schema Information
#
# Table name: tenants
#
#  id                   :bigint           not null, primary key
#  api_token_public_key :string
#  feature_flags        :string           default([]), is an Array
#  name                 :string           not null
#  settings             :jsonb            not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class Tenant < ApplicationRecord
  has_many :users, dependent: :destroy

  has_one :all_group
  has_one :signer_group
  has_one :admin_group
  has_many :groups, dependent: :destroy
  has_many :custom_groups

  has_one :draft_tag, -> { where(owner_id: nil) }
  has_one :everything_tag
  has_one :inbox_tag
  has_one :signature_requested_tag
  has_one :signed_tag
  has_one :signed_externally_tag
  has_one :archived_tag
  has_one :submitted_tag
  has_one :submission_error_tag
  has_one :unprocessable_tag
  has_many :tags, dependent: :destroy
  has_many :signature_requested_from_tags
  has_many :signed_by_tags
  has_many :simple_tags

  has_many :boxes, dependent: :destroy
  has_many :api_connections, dependent: :destroy
  has_many :automation_rules, class_name: "Automation::Rule", dependent: :destroy
  has_many :filters
  has_many :filter_subscriptions
  has_many :automation_webhooks, class_name: "Automation::Webhook", dependent: :destroy
  has_many :message_threads, through: :boxes
  has_many :messages, through: :message_threads

  after_create :create_default_objects

  validates_presence_of :name

  AVAILABLE_FEATURE_FLAGS = [:audit_log, :archive, :api, :fs_sync]
  ALL_FEATURE_FLAGS = [:audit_log, :archive, :api, :message_draft_import, :fs_api, :fs_sync, :autogram_portal]

  PDF_SIGNATURE_FORMATS = %w[PAdES XAdES CAdES]

  def agp_sub
    # TODO
    1
  end

  def set_pdf_signature_format(pdf_signature_format)
    raise "Unknown pdf_signature_format #{pdf_signature_format}" unless pdf_signature_format.in? PDF_SIGNATURE_FORMATS

    self.settings["pdf_signature_format"] = pdf_signature_format
    save!
  end

  def signature_settings
    pdf_signature_format = if PDF_SIGNATURE_FORMATS.include?(settings["pdf_signature_format"])
      settings["pdf_signature_format"]
    else
      PDF_SIGNATURE_FORMATS[0]
    end

    settings.slice("signature_with_timestamp").merge!({"pdf_signature_format" => pdf_signature_format})
  end

  def draft_tag!
    draft_tag || raise(ActiveRecord::RecordNotFound, "`DraftTag` not found in tenant: #{id}")
  end

  def signed_externally_tag!
    signed_externally_tag || raise(ActiveRecord::RecordNotFound, "`SignedExternallyTag` not found in tenant: #{id}")
  end

  def signature_requested_tag!
    signature_requested_tag || raise(ActiveRecord::RecordNotFound, "`SignatureRequestedTag` not found in tenant: #{id}")
  end

  def signed_tag!
    signed_tag || raise(ActiveRecord::RecordNotFound, "`SignedTag` not found in tenant: #{id}")
  end

  def user_signature_tags
    tags.where(type: %w[SignatureRequestedFromTag SignedByTag])
  end

  def unprocessable_tag!
    unprocessable_tag || raise(ActiveRecord::RecordNotFound, "`UnprocessableTag` not found in tenant: #{id}")
  end

  def submission_error_tag!
    submission_error_tag || raise(ActiveRecord::RecordNotFound, "`SubmissionErrorTag` not found in tenant: #{id}")
  end

  def feature_enabled?(feature)
    raise "Unknown feature #{feature}" unless feature.in? ALL_FEATURE_FLAGS

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

  def list_available_features
    AVAILABLE_FEATURE_FLAGS
  end

  def list_all_features
    ALL_FEATURE_FLAGS
  end

  def make_admins_see_everything!
    everything_tag.groups << admin_group
  end

  def self.create_with_admin!(tenant_params, admin_params)
    tenant = create!(name: tenant_params[:name])
    admin = tenant.users.create!(admin_params)
    tenant.admin_group.users << admin
    tenant
  end

  private

  def create_default_objects
    create_all_group!(name: "all")
    create_admin_group!(name: "admins")
    create_signer_group!(name: "signers")

    create_draft_tag!(name: "Rozpracované", visible: true)
    create_everything_tag!(name: "Všetky správy", visible: false)
    create_inbox_tag!(name: "Doručené", visible: false)
    create_archived_tag!(name: "Archivované", color: "green", icon: "archive-box", visible: true)
    create_signature_requested_tag!(name: "Na podpis", visible: true, color: "yellow", icon: "pencil")
    create_signed_tag!(name: "Podpísané", visible: true, color: "green", icon: "fingerprint")
    signer_group.create_signature_requested_tag!
    create_signed_externally_tag!(name: "Externe podpísané", visible: false, color: "purple", icon: "shield-check")
    create_submitted_tag!(name: 'Odoslané na spracovanie')
    create_submission_error_tag!(name: 'Problémové')
    create_unprocessable_tag!(name: 'Chybné', color: 'red', icon: 'exclamation-triangle')

    make_admins_see_everything!
  end
end
